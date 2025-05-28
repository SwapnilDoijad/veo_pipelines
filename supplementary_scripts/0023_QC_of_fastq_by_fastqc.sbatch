#!/bin/bash
#SBATCH --job-name=0023_QC_of_fastq_by_fastqc
#SBATCH --partition=short
#SBATCH --output=results/0023_QC_of_fastq_by_fastqc/tmp/slurm/%j.out
#SBATCH --error=results/0023_QC_of_fastq_by_fastqc/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
###############################################################################
pipeline=0023_QC_of_fastq_by_fastqc
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )

    for i in $(cat $sublist ); do
        log "RUNNING: $i"

        ( mkdir $raw_files/$i ) > /dev/null 2>&1
        /home/groups/VEO/tools/fastqc/v0.12.1/fastqc -o $raw_files/$i \
        -t $SLURM_CPUS_PER_TASK \
        --memory 10000 -q $fastq_path/"$i"*.fastq.gz \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$i.fastqc.tsv 

        log "FINISHED: $i"
    done

###############################################################################