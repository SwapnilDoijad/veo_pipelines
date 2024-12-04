#!/bin/bash
#SBATCH --job-name 0004_subsample_fastq_reads_by_rasusa
#SBATCH --partition=gpu
#SBATCH --output results/0004_subsample_fastq_reads_by_rasusa/tmp/slurm/%j.out
#SBATCH --error results/0004_subsample_fastq_reads_by_rasusa/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0004_subsample_fastq_reads_by_rasusa
    wd=results/$pipeline

    sublist=$wd/tmp/lists/ABC
    parameters=tmp/parameters/$pipeline.*
###############################################################################
## step-02: running rasusa
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 

    for i in $(cat $sublist ); do 
    log "STARTED: $pipeline : $i"
        fastq_path=$( grep my_fastqs $parameters | awk '{print $2}')
        subsample=$( grep my_subsample $parameters | awk '{print $2}' )

        rasusa \
        -i $fastq_path/"$i"_R1.fastq.gz \
        -i $fastq_path/"$i"_R2.fastq.gz \
        -n $subsample \
        -o $wd/raw_files/"$i"_"$subsample"_R1.fastq.gz \
        -o $wd/raw_files/"$i"_"$subsample"_R2.fastq.gz

    log "FINISHED : $pipeline : $i"

    done 

###############################################################################