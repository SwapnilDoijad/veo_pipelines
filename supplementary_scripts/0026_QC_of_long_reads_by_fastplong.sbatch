#!/bin/bash
#SBATCH --job-name 0025_QC_of_paired-fastq_by_fastp
#SBATCH --partition=short
#SBATCH --output results/0025_QC_of_paired-fastq_by_fastp/tmp/slurm/%j.out
#SBATCH --error results/0025_QC_of_paired-fastq_by_fastp/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
###############################################################################
pipeline=0025_QC_of_paired-fastq_by_fastp
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC


    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate fastp_v0.23.4

    for i in $(cat $sublist ); do
        if [ ! -f $raw_files/$i.html ] ; then 
            log "STARTED : fastp for $i" 

            fastp \
            --thread 16 \
            -i $data_directory_fastq_path/"$i"_*R1*fastq.gz \
            -I $data_directory_fastq_path/"$i"_*R2*fastq.gz \
            -o $raw_files/"$i"_R1.fastq.gz \
            -O $raw_files/"$i"_R2.fastq.gz  \
            --html $raw_files/$i.html &>> $wd/fastp.out

            ## 202403 raw reads calculations. fastp do not count reads in the same way as zcat 
            f_reads=$(zcat $data_directory_fastq_path/"$i"_*R1*fastq.gz | wc -l | awk '{print $1/4}')
            r_reads=$(zcat $data_directory_fastq_path/"$i"_*R2*fastq.gz | wc -l | awk '{print $1/4}')
            filt_f_reads=$(zcat $raw_files/"$i"_*R1*fastq.gz | wc -l | awk '{print $1/4}')
            filt_r_reads=$(zcat $raw_files/"$i"_*R2*fastq.gz | wc -l | awk '{print $1/4}')

            total_reads=$((f_reads + r_reads))
            filt_total_reads=$((filt_f_reads + filt_r_reads))
            echo -e "$i\t$f_reads\t$r_reads\t$total_reads\t$filt_f_reads\t$filt_r_reads\t$filt_total_reads" >> $wd/stat.raw_read_count.tsv

            log "FINISHED : fastp for $i"  
            else 
            log "ALREADY FINISHED : fastp for $i"
        fi
    done
###############################################################################