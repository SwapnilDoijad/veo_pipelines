#!/bin/bash
#SBATCH --job-name=0025_QC_of_paired_fastq_by_fastp
#SBATCH --partition=short,standard,interactive,long,gpu,gpu-test,gpu-veo
#SBATCH --output=results/0025_QC_of_paired_fastq_by_fastp/tmp/slurm/%j.out
#SBATCH --error=results/0025_QC_of_paired_fastq_by_fastp/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
###############################################################################
    pipeline=0025_QC_of_paired_fastq_by_fastp
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
###############################################################################
	log "STARTED : $pipeline for $sublist" && clean
###############################################################################
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh \
    && conda activate fastp_v0.23.4

    for i in $(cat $sublist ); do
        if [ ! -f $raw_files/$i.html ] ; then 
            log "STARTED : fastp for $i" 

            fastp \
            --thread $SLURM_CPUS_PER_TASK \
            -i $fastq_path/"$i"_*R1*fastq.gz \
            -I $fastq_path/"$i"_*R2*fastq.gz \
            -o $raw_files/"$i"_R1.fastq.gz \
            -O $raw_files/"$i"_R2.fastq.gz \
            --html $raw_files/$i.html &>> $wd/fastp.out

            mv $raw_files/$i.html $wd/$i.html

            ## 202403 raw reads calculations. fastp do not count filt_f_reads filt_r_reads seperately
            f_reads=$(zcat $fastq_path/"$i"_*R1*fastq.gz | wc -l | awk '{print $1/4}')
            r_reads=$(zcat $fastq_path/"$i"_*R2*fastq.gz | wc -l | awk '{print $1/4}')
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
	log "FINISHED : $pipeline for $sublist" && clean
###############################################################################