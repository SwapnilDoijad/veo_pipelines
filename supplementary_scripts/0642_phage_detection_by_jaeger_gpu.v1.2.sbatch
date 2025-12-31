#!/bin/bash
###############################################################################
#SBATCH --job-name=0642_phage_detection_by_jaeger_gpu
#SBATCH --partition=gpu-veo
#SBATCH --output=results/0642_phage_detection_by_jaeger_gpu/tmp/slurm/%j.out
#SBATCH --error=results/0642_phage_detection_by_jaeger_gpu/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
###############################################################################
## step-01: preparation
    pipeline=0642_phage_detection_by_jaeger_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_path=$(grep "fasta_path" $parameters | awk '{print $2}')

    module load nvidia/cuda/12.1.0
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate jaeger_v20250624
    export XLA_GPU_CUDA_DATA_DIR=/cluster/nvidia/cuda/12.4.0/
    export TF_CPP_MIN_LOG_LEVEL=3
    echo "pipeline: $pipeline"
    echo "sublist: $sublist"
    echo "fasta_path: $fasta_path"
###############################################################################
## step-02: main command 

    log "STARTED : $pipeline : sbatch for $sublist"

    for i in $(cat $sublist); do 
        if [ ! -d $raw_files/prophage/$i ] ; then
            log "STARTED : $pipeline : sbatch for $sublist : $i "

            ## fasta should contain only upper case letters
            python $suppl_scripts/utilities/reformat_fasta.py \
            -i $fasta_path/$i.fasta \
            -o $fasta_path/$i.fasta.tmp

            mv $fasta_path/$i.fasta.tmp $fasta_path/$i.fasta

            ## testing model 
            jaeger predict \
            -i $fasta_path/$i.fasta \
            -o $raw_files/phage/$i \
            -m jaeger_57341_1.5M_fragment \
            --batch 100 \
            & my_pid=$!
            get_resource_stat $my_pid $wd/tmp/resource_log/$i.jaeger.prophage.tsv 

            # jaeger predict \
            # -i $fasta_path/$i.fasta \
            # -o $raw_files/phage/$i \
            # -m jaeger_57341_1.5M_fragment \
            # --batch 100 \
            # & my_pid=$!
            # get_resource_stat $my_pid $wd/tmp/resource_log/$i.jaeger.prophage.tsv 

            log "FINISHED : $pipeline : sbatch for $sublist : $i "
        else
            log "ALREADY FINISHED : $pipeline : sbatch for $sublist : $i "
        fi 
    done

###############################################################################
## step-04: post-processing

    for i in $(cat $sublist); do 
        prophage_count=$(tail -n +2 $raw_files/prophage/$i/"$i"_default_prophages/prophages_jaeger.tsv  | wc  -l)
        phage_count=$( awk -F'\t' '$3=="phage" {print $0}' $raw_files/prophage/$i/"$i"_default_jaeger.tsv | wc -l )
        echo -e "$i\t$phage_count\t$prophage_count" | tee -a $wd/phage_prophage_count.tsv
    done

    ## extract phage fasta
    for i in $(cat $sublist); do
        if [ ! -f $wd/extracted_fasta/$i/$i.phage.fasta ] ; then 
            log "STARTED : $pipeline : extracting fasta for $i"
            mkdir -p $wd/extracted_fasta/$i

            awk -F'\t' '$3=="phage" {print $1}' \
            $raw_files/prophage/$i/"$i"_default_jaeger.tsv \
            > $raw_files/prophage/$i/$i.contigs_jaeger.tsv.phage.list

            if [ -s $raw_files/prophage/$i/$i.contigs_jaeger.tsv.phage.list ]; then
                /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl \
                -X \
                -f $raw_files/prophage/$i/$i.contigs_jaeger.tsv.phage.list \
                $fasta_path/$i.fasta \
                > $wd/extracted_fasta/$i/$i.phage.fasta
                
                sed -i "s/>/>"$i"_phage/g" $wd/extracted_fasta/$i/$i.phage.fasta
                sed -i "s/ /_/g" $wd/extracted_fasta/$i/$i.phage.fasta

                /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
                -i $wd/extracted_fasta/$i/$i.phage.fasta \
                -o $wd/extracted_fasta/$i
                
                rm -rf $wd/extracted_fasta/$i/$i.phage.fasta
            fi

            ## extract prophage fasta
            awk -F'\t' 'NR>1 {print $1, $9, $12}' \
            $raw_files/prophage/$i/"$i"_default_prophages/prophages_jaeger.tsv \
            > $raw_files/prophage/$i/$i.contigs_jaeger.tsv.prophage.list

            while read contig_id start end; do
                /home/groups/VEO/tools/samtools/v1.17/bin/samtools faidx \
                $fasta_path/$i.fasta \
                $contig_id:"$start"-"$end" \
                > $wd/extracted_fasta/$i/"$i"_"$contig_id"_"$start"_"$end".prophage.fasta

                rm -rf $fasta_path/$i.fasta.fai
            done < $raw_files/prophage/$i/$i.contigs_jaeger.tsv.prophage.list


            log "FINISHED : $pipeline : extracting fasta for $i"
            else
            log "ALREADY FINISHED : $pipeline : extract fasta for $i"
        fi 
    done

###############################################################################
## step: calculate stat 
    # summarize_usage() {
    #     local log_file=$1
    #     local fasta_file=$2

    #     if [ ! -f "$log_file" ]; then
    #         echo "Log file not found!"
    #         return 1
    #     fi

    #     if [ ! -f "$fasta_file" ]; then
    #         echo "FASTA file not found!"
    #         return 1
    #     fi

    #     # Extract the ID from the file name
    #     local file_name=$(basename "$log_file")
    #     local id=$(echo "$file_name" | awk -F_ '{print $1}')

    #     # Initialize variables for summing the values and storing unique CPU usages
    #     local total_cpu_usage=0
    #     local total_mem_usage=0
    #     local total_cpus_used=0
    #     local total_gpu_usage=0
    #     local total_gpu_mem=0
    #     local count=0
    #     declare -A unique_cpus

    #     local first_timestamp=""
    #     local last_timestamp=""

    #     # Read the log file line by line, skipping the header
    #     while IFS=, read -r timestamp cpu_usage mem_usage cpus_used gpu_usage gpu_mem; do
    #         # Skip the header
    #         if [ "$timestamp" == "Timestamp" ]; then
    #             continue
    #         fi

    #         # Record the first and last timestamps
    #         if [ -z "$first_timestamp" ]; then
    #             first_timestamp=$timestamp
    #         fi
    #         last_timestamp=$timestamp

    #         total_cpu_usage=$(echo "$total_cpu_usage + $cpu_usage" | bc -l)
    #         total_mem_usage=$(echo "$total_mem_usage + $mem_usage" | bc -l)
    #         total_cpus_used=$(echo "$total_cpus_used + $cpus_used" | bc -l)
    #         total_gpu_usage=$(echo "$total_gpu_usage + $gpu_usage" | bc -l)
    #         total_gpu_mem=$(echo "$total_gpu_mem + $gpu_mem" | bc -l)
    #         unique_cpus["$cpus_used"]=1
    #         count=$((count + 1))
    #     done < "$log_file"

    #     if [ $count -eq 0 ]; then
    #         echo "No data to summarize."
    #         return 1
    #     fi

    #     # Calculate averages
    #     avg_cpu_usage=$(echo "scale=2; $total_cpu_usage / $count" | bc -l)
    #     avg_mem_usage_gb=$(echo "scale=2; $total_mem_usage / 1024 / 1024 / $count" | bc -l)
    #     avg_cpus_used=$(echo "scale=2; $total_cpus_used / $count" | bc -l)
    #     avg_gpu_usage=$(echo "scale=2; $total_gpu_usage / $count" | bc -l)
    #     avg_gpu_mem_gb=$(echo "scale=2; $total_gpu_mem / 1024 / 1024 / $count" | bc -l)
    #     num_unique_cpus=${#unique_cpus[@]}

    #     # Calculate total time required
    #     start_time=$(date -d "$first_timestamp" +%s)
    #     end_time=$(date -d "$last_timestamp" +%s)
    #     total_time=$(($end_time - $start_time))

    #     # Calculate total nucleotides processed
    #     total_nucleotides=0
    #     while read -r line; do
    #         if [[ ! $line =~ ^\> ]]; then
    #             total_nucleotides=$((total_nucleotides + ${#line}))
    #         fi
    #     done < "$fasta_file"
    #     total_nucleotides_mb=$(echo "scale=2; $total_nucleotides / 1024 / 1024 " | bc)

    #     # Display summary
    #     echo -e "$id\t$num_unique_cpus\t$avg_cpu_usage\t$avg_cpus_used\t$avg_gpu_usage\t$avg_gpu_mem_gb\t$total_time\t$avg_mem_usage_gb\t$total_nucleotides_mb"
    # }

    # for i in $(cat $sublist); do 
    #     summarize_usage $wd/logs/"$i"*.log $fasta_path/"$i"*.fasta | tee -a $wd/usage_stat.tsv
    # done


    # $avg_cpu_usage:
        # Definition: This is the average percentage of CPU usage by the process over the logging period.
        # Calculation: It is calculated by summing all recorded CPU usage percentages and then dividing by the number of records.
        # Units: Percentage (%).

    # $avg_cpus_used:
        # Definition: This is the average number of CPU cores used by the process, calculated based on the CPU usage percentage and the total number of cores available.
        # Calculation: For each record, the CPU usage percentage is converted to a fraction of the total number of cores (e.g., if the CPU usage is 50% on a system with 4 cores, it would be 2 cores). These values are summed and then divided by the number of records.
        # Units: Number of CPU cores (fractional).

    # $num_unique_cpus:
        # Definition: This is the count of unique CPU usage values recorded during the logging period.
        # Calculation: Each distinct value of CPUs used (calculated from the CPU usage percentage) is tracked. The number of distinct values is then counted.
        # Units: Number of unique CPU usage values.

    # $total_time
        # Definition: This is the total duration for which the logging was performed.
        # Calculation: It is calculated by finding the difference between the first and the last timestamps in the log file.
        # Units: Seconds.

    # $avg_mem_usage_gb
        # Definition: This is the average memory usage of the process during the logging period, converted to gigabytes (GB).
        # Calculation: First, calculate the total memory usage across all records. Divide by the number of records to get the average memory usage in kilobytes (KB). Convert the average memory usage from KB to GB by dividing by 1024 twice (since 1 GB = 1024 MB and 1 MB = 1024 KB).
        # Units: Gigabytes (GB).

    # $total_nucleotides_kb
        # Definition: This is the total number of nucleotides processed, converted to kilobytes (KB).
        # Calculation: Sum the lengths of all sequences in the FASTA file to get the total number of nucleotides. Convert the total nucleotide count to KB by dividing by 1024 (since 1 KB = 1024 bytes, and assuming 1 nucleotide = 1 byte).
        # Units: Kilobytes (KB).

    # $gpu_usage
        # Description: gpu_usage represents the percentage of the GPU's computational resources that are being used.
        # Source: This value is retrieved from the output of the nvidia-smi command, which queries the GPU for its current utilization metrics.

    # $gpu_mem
        # Description: gpu_mem shows the amount of GPU memory currently in use, measured in megabytes (MB).
        # Source: This value is obtained from the nvidia-smi command output, specifically querying the GPU memory usage.

###############################################################################
    log "ENDED : $pipeline : sbatch for $sublist" && clean
###############################################################################

    # /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl -X \
    # -f results/0642_phage_detection_by_jaeger_gpu/raw_files/zr11465-08.contigs_jaeger.tsv.phage.list \
    # results/0055_metagenome_assembly_by_megahit_for_illumina/all_fasta/zr11465-08.contigs.fasta \
    # > results/0642_phage_detection_by_jaeger_gpu/extracted_fasta/zr11465-08.phage.fasta
