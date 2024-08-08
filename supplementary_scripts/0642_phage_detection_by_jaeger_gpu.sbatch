#!/bin/bash
###############################################################################
#SBATCH --job-name 0642_phage_detection_by_jaeger_gpu
#SBATCH --partition=gpu
#SBATCH --output results/0642_phage_detection_by_jaeger_gpu/tmp/slurm/%j.out
#SBATCH --error results/0642_phage_detection_by_jaeger_gpu/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
###############################################################################
## step-01: preparation
    pipeline=0642_phage_detection_by_jaeger_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    # sublist=$wd/tmp/lists/ABC
    sublist=list.fasta.txt

    module load nvidia/cuda/12.1.0
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate jaeger_dev
    # conda activate jaeger_v1.1.30a0
    # conda activate jaeger_v240529
    # module load nvidia/cuda/11.7 

###############################################################################
## step-02: main command 

    log "STARTED : $pipeline : sbatch for $sublist"

    mkdir -p $wd/logs > /dev/null 2>&1
    # Function to log resource usage
    log_usage() {
        local pid=$1
        local log_file=$2
        local num_cores=$(nproc)
        echo "Timestamp, CPU (%), Memory (KB), CPUs_used, gpu_usage, gpu_mem (MB)" > "$log_file"
        while kill -0 $pid 2> /dev/null; do
            ps_output=$(ps -p $pid -o %cpu,rss --no-headers)
            cpu_usage=$(echo "$ps_output" | awk '{print $1}')
            mem_usage=$(echo "$ps_output" | awk '{print $2}') 
            cpus_used=$(echo "$cpu_usage * $num_cores / 100" | bc -l)

            # gpu_output=$(nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits)
            # gpu_usage=$(echo "$gpu_output" | awk -F ',' '{print $1}')
            # gpu_mem=$(echo "$gpu_output" | awk -F ',' '{print $2}')
            
            echo "$(date '+%Y-%m-%d %H:%M:%S'), $cpu_usage, $mem_usage, $cpus_used, $gpu_usage, $gpu_mem" >> "$log_file"
            sleep 1

        done
    }

    for i in $(cat $sublist); do 
        if [ ! -d $raw_files/$i ] ; then
            log "STARTED : $pipeline : sbatch for $sublist : $i "
            
            export TF_CPP_MIN_LOG_LEVEL=3
            fasta_path=$(grep $i tmp/parameters/$pipeline.txt )

            # Run Jaeger in the background
            # Jaeger -i $fasta_path -o $wd/raw_files/ --batch 40 &
            python3 /home/groups/VEO/tools/jaeger/v1.1.30a0/Jaeger/bin/jaeger run \
            -i $fasta_path -o $wd/raw_files/ --batch 40 &
            jaeger_pid=$!

            # Log resource usage
            log_usage $jaeger_pid "$wd/logs/${i}_usage.log" &
            usage_pid=$!

            # Wait for Jaeger to finish
            wait $jaeger_pid

            # Ensure logging stops
            wait $usage_pid

            log "FINISHED : $pipeline : sbatch for $sublist : $i "
        else
            log "ALREADY FINISHED : $pipeline : sbatch for $sublist : $i "
        fi 
    done

###############################################################################
## step-03: calculate stat 
    summarize_usage() {
        local log_file=$1
        local fasta_file=$2

        if [ ! -f "$log_file" ]; then
            echo "Log file not found!"
            return 1
        fi

        if [ ! -f "$fasta_file" ]; then
            echo "FASTA file not found!"
            return 1
        fi

        # Extract the ID from the file name
        local file_name=$(basename "$log_file")
        local id=$(echo "$file_name" | awk -F_ '{print $1}')

        # Initialize variables for summing the values and storing unique CPU usages
        local total_cpu_usage=0
        local total_mem_usage=0
        local total_cpus_used=0
        local total_gpu_usage=0
        local total_gpu_mem=0
        local count=0
        declare -A unique_cpus

        local first_timestamp=""
        local last_timestamp=""

        # Read the log file line by line, skipping the header
        while IFS=, read -r timestamp cpu_usage mem_usage cpus_used gpu_usage gpu_mem; do
            # Skip the header
            if [ "$timestamp" == "Timestamp" ]; then
                continue
            fi

            # Record the first and last timestamps
            if [ -z "$first_timestamp" ]; then
                first_timestamp=$timestamp
            fi
            last_timestamp=$timestamp

            total_cpu_usage=$(echo "$total_cpu_usage + $cpu_usage" | bc -l)
            total_mem_usage=$(echo "$total_mem_usage + $mem_usage" | bc -l)
            total_cpus_used=$(echo "$total_cpus_used + $cpus_used" | bc -l)
            total_gpu_usage=$(echo "$total_gpu_usage + $gpu_usage" | bc -l)
            total_gpu_mem=$(echo "$total_gpu_mem + $gpu_mem" | bc -l)
            unique_cpus["$cpus_used"]=1
            count=$((count + 1))
        done < "$log_file"

        if [ $count -eq 0 ]; then
            echo "No data to summarize."
            return 1
        fi

        # Calculate averages
        avg_cpu_usage=$(echo "scale=2; $total_cpu_usage / $count" | bc -l)
        avg_mem_usage_gb=$(echo "scale=2; $total_mem_usage / 1024 / 1024 / $count" | bc -l)
        avg_cpus_used=$(echo "scale=2; $total_cpus_used / $count" | bc -l)
        avg_gpu_usage=$(echo "scale=2; $total_gpu_usage / $count" | bc -l)
        avg_gpu_mem_gb=$(echo "scale=2; $total_gpu_mem / 1024 / 1024 / $count" | bc -l)
        num_unique_cpus=${#unique_cpus[@]}

        # Calculate total time required
        start_time=$(date -d "$first_timestamp" +%s)
        end_time=$(date -d "$last_timestamp" +%s)
        total_time=$(($end_time - $start_time))

        # Calculate total nucleotides processed
        total_nucleotides=0
        while read -r line; do
            if [[ ! $line =~ ^\> ]]; then
                total_nucleotides=$((total_nucleotides + ${#line}))
            fi
        done < "$fasta_file"
        total_nucleotides_mb=$(echo "scale=2; $total_nucleotides / 1024 / 1024 " | bc)

        # Display summary
        echo -e "$id\t$num_unique_cpus\t$avg_cpu_usage\t$avg_cpus_used\t$avg_gpu_usage\t$avg_gpu_mem_gb\t$total_time\t$avg_mem_usage_gb\t$total_nucleotides_mb"
    }

    for i in $(cat $sublist); do 
        summarize_usage $wd/logs/"$i"*.log $fasta_path/"$i"*.fasta | tee -a $wd/usage_stat.tsv
    done

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

exit 
###############################################################################
## step-04: post-processing

    for i in $(cat $sublist); do 
        awk -F'\t' '$7=="Phage" {print $0}' $wd/raw_files/$i.contigs_jaeger.tsv \
        > $wd/raw_files/$i.contigs_jaeger.tsv.phage.tsv 
        phage_count=$( wc -l $wd/raw_files/$i.contigs_jaeger.tsv.phage.tsv | awk '{print $1}' )
        echo -e "$i\t$phage_count" | tee -a $wd/phage_count.tsv
    done

    for i in $(cat $sublist); do
        if [ ! -f $wd/extracted_fasta/$i/$i.phage.fasta ] ; then 
            log "STARTED : $pipeline : extracting fasta for $i"
            mkdir -p $wd/extracted_fasta/$i
            fasta_path=$(grep $i tmp/parameters/$pipeline.txt )

            awk '{print $1}' $wd/raw_files/$i.contigs_jaeger.tsv.phage.tsv \
            > $wd/raw_files/$i.contigs_jaeger.tsv.phage.list

            /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl \
            -X \
            -f $wd/raw_files/$i.contigs_jaeger.tsv.phage.list \
            $fasta_path \
            > $wd/extracted_fasta/$i/$i.phage.fasta
            

            sed -i "s/>/>$i/g" $wd/extracted_fasta/$i/$i.phage.fasta
            sed -i "s/ /_/g" $wd/extracted_fasta/$i/$i.phage.fasta

            log "FINISHED : $pipeline : extracting fasta for $i"
            else
            log "ALREADY FINISHED : $pipeline : extract fasta for $i"
        fi 
    done

    for i in $(cat $sublist); do
        if [ ! -d $wd/extracted_fasta_split_all ] ; then 
            log "STARTED : $pipeline : $i : split fasta step "
            mkdir -p $wd/extracted_fasta_split/$i
            mkdir -p $wd/extracted_fasta_split_all

            bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
            -i $wd/extracted_fasta/$i/$i.phage.fasta \
            -o $wd/extracted_fasta_split/$i 

            bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
            -i $wd/extracted_fasta/$i/$i.phage.fasta \
            -o $wd/extracted_fasta_split_all
            else
            log "ALREADY FINISHED : $pipeline : $i : split fasta step "
        fi
    done

###############################################################################


# /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl -X \
# -f results/0642_phage_detection_by_jaeger_gpu/raw_files/zr11465-08.contigs_jaeger.tsv.phage.list \
# results/0055_metagenome_assembly_by_megahit_for_illumina/all_fasta/zr11465-08.contigs.fasta \
# > results/0642_phage_detection_by_jaeger_gpu/extracted_fasta/zr11465-08.phage.fasta
