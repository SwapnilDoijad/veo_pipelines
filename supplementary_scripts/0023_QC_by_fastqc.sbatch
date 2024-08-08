#!/bin/bash
#SBATCH --job-name 0025_QC_of_paired-fastq_by_fastp
#SBATCH --partition=short
#SBATCH --output results/0025_QC_of_paired-fastq_by_fastp/tmp/slurm/%j.out
#SBATCH --error results/0025_QC_of_paired-fastq_by_fastp/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
###############################################################################
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC

    for i in $(cat $sublist ); do
        echo "running script 0023_QC_by_fastqc for $i"
        ( mkdir $raw_files/$i ) > /dev/null 2>&1
        $fastqc -o $raw_files/$i -t 10 --memory 10000 -q $data_directory_fastq_path/"$i"*.fastq.gz
    done

###############################################################################