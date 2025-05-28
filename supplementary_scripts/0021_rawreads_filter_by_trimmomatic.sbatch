#!/bin/bash
#SBATCH --job-name 0021_rawreads_filter_by_trimmomatic
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu
#SBATCH --output results/0021_rawreads_filter_by_trimmomatic/tmp/slurm/%j.out
#SBATCH --error  results/0021_rawreads_filter_by_trimmomatic/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
###############################################################################
echo "SBATCH STARTED : 0021_rawreads_filter_by_trimmomatic"
###############################################################################  
## step-01: preparation
    pipeline=0021_rawreads_filter_by_trimmomatic
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fastq_file_path=$(grep "my_fastq_path" $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC
    cpus=$SLURM_CPUS_PER_TASK
    
############################################################################### 
## step-02: run trimmomatic 
## subsampling ? 
    # echo "--------------------------------------------------------------------------------"
    # echo "Do you want to sample the reads,type y else press ENTER to continue"
    #     read answer
    #     if [ "$answer" == "y" ]; then
    #         echo "what is the expected size of the genome? (for eg. 5000000)"
    #         read genome_size
    #         echo "How much genome coverage needed? (for eg. 60)"
    #         read user_coverage
    #         for F1 in $(cat $list); do
    #             echo "running.... 0021_filter_rawreads started for..." $i 
    #             (mkdir -p $wd/raw_files/$i/raw_reads_sampled)> /dev/null 2>&1
    #             #read sampling ---------------------------------------------------------------------

    #             ARL=$(awk '{print $4}' results/01_raw_read_count/$i/"$i".1_raw_read_count.statistics.tab | awk -F'.' '{print $1}')
    #             reads_for_desired_coverage=$(( $genome_size * $user_coverage / $ARL ))
    #             /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk sample -s100 $fastq_file_path/"$i"_*R1*.fastq.gz $reads_for_desired_coverage > $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R1.fastq
    #             /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk sample -s100 $fastq_file_path/"$i"_*R2*.fastq.gz $reads_for_desired_coverage > $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R2.fastq
    #             gzip -c $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R1.fastq > $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R1.fastq.gz
    #             gzip -c $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R2.fastq > $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R2.fastq.gz

    #             rm $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R1.fastq 
    #             rm $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R2.fastq 

    #             ## read sampling: Filter reads by trimmOMATIC------------------------------------
    #             java -jar /home/groups/VEO/tools/trimmomatic/v0.39/trimmomatic-0.39.jar PE -threads 8 -phred33 -quiet \
    #             $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R1.fastq.gz \
    #             $wd/raw_files/$i/raw_reads_sampled/"$i"_sampled_R1.fastq.gz \
    #             $wd/raw_files/$i/"$i"_R1*.filtered_paired.fastq.gz \
    #             $wd/raw_files/$i/"$i"_R1*.filtered_unpaired.fastq.gz \
    #             $wd/raw_files/$i/"$i"_R2*.filtered_paired.fastq.gz \
    #             $wd/raw_files/$i/"$i"_R2*.filtered_unpaired.fastq.gz \
    #             ILLUMINACLIP:/home/groups/VEO/tools/trimmomatic/v0.39/adapters/TruSeq2-PE.fa:2:30:10 LEADING:6 TRAILING:6 SLIDINGWINDOW:4:20 MINLEN:36
    #             #### read sampling: FIlter reads by trimmOMATIC -------------------------------

    #             echo "finished... 0021_filter_rawreads started for..." $i
    #         done
    #     fi
###############################################################################
## without sampling
    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/"$i"_R1*.filtered_paired.fastq.gz ] ; then 
            log "STARTED : $pipeline : $i" 
            ( mkdir $wd/raw_files/$i )> /dev/null 2>&1
            java -jar /home/groups/VEO/tools/trimmomatic/v0.39/trimmomatic-0.39.jar \
            PE -threads $cpus -phred33 -quiet \
            $fastq_file_path/"$i"_*R1*.fastq.gz \
            $fastq_file_path/"$i"_*R2*.fastq.gz \
            $raw_files/$i/"$i"_R1_001.filtered_paired.fastq.gz \
            $raw_files/$i/"$i"_R1_001.filtered_unpaired.fastq.gz \
            $raw_files/$i/"$i"_R2_001.filtered_paired.fastq.gz \
            $raw_files/$i/"$i"_R2_001.filtered_unpaired.fastq.gz \
            -trimlog $wd/raw_files/$i/trimlog.log \
            -summary $wd/raw_files/$i/summary.txt \
            ILLUMINACLIP:/home/groups/VEO/tools/trimmomatic/v0.39/adapters/TruSeq2-PE.fa:2:30:10 LEADING:6 TRAILING:6 SLIDINGWINDOW:4:20 MINLEN:36

            mv $wd/fastq_filtered/*.filtered_paired.fastq.gz $wd/fastq_filtered/

            log "Counting reads: $i"
            f_raw_reads=$( count_reads_from_fastq $fastq_file_path/"$i"_*R1*.fastq.gz )
            r_raw_reads=$( count_reads_from_fastq $fastq_file_path/"$i"_*R2*.fastq.gz )
            total_raw_reads=$(( $f_raw_reads + $r_raw_reads))

            raw_f_arl=$(zcat $fastq_file_path/"$i"_*R1*.fastq.gz | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' | awk '{$3=$1*$2; C+=$3; B+=$2; ARL= C / B} END {print ARL}')
            raw_r_arl=$(zcat $fastq_file_path/"$i"_*R2*.fastq.gz | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' | awk '{$3=$1*$2; C+=$3; B+=$2; ARL= C / B} END {print ARL}')
            raw_arl=$( awk "BEGIN {print ($raw_f_arl+$raw_r_arl)/2; exit}" | awk -F'.' '{print $1}')

            f_filtered_reads=$( count_reads_from_fastq $raw_files/$i/"$i"_R1_001.filtered_paired.fastq.gz )
            r_filtered_reads=$( count_reads_from_fastq $raw_files/$i/"$i"_R2_001.filtered_paired.fastq.gz )
            total_filtered_reads=$(( $f_filtered_reads + $r_filtered_reads ))

            filtered_f_arl=$(zcat $raw_files/$i/"$i"_R1_001.filtered_paired.fastq.gz | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' | awk '{$3=$1*$2; C+=$3; B+=$2; ARL= C / B} END {print ARL}')
            filtered_r_arl=$(zcat $raw_files/$i/"$i"_R2_001.filtered_paired.fastq.gz | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' | awk '{$3=$1*$2; C+=$3; B+=$2; ARL= C / B} END {print ARL}')
            filtered_arl=$( awk "BEGIN {print ($filtered_f_arl+$filtered_r_arl)/2; exit}" | awk -F'.' '{print $1}')

	        echo "$i $f_raw_reads $r_raw_reads $raw_arl $total_raw_reads $f_filtered_reads $r_filtered_reads $filtered_arl $total_filtered_reads" | tr ' ' '\t' >> $wd/summary.tsv

            log "FINISHED : $pipeline : $i"

        else
            log "ALREADY FINISHED :$pipeline : $i"
        fi
    done
###############################################################################
echo "SBATCH ENDED : 0021_rawreads_filter_by_trimmomatic"
###############################################################################


# ILLUMINACLIP:/home/groups/VEO/tools/trimmomatic/v0.39/adapters/TruSeq2-PE.fa:2:30:10 LEADING:6 TRAILING:6 SLIDINGWINDOW:4:20 MINLEN:36