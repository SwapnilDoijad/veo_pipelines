#!/bin/bash
#SBATCH --job-name=0022_QC_of_nanopore_fastq_by_nanoplot
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu,gpu-test
#SBATCH --output=results/0022_QC_of_nanopore_fastq_by_nanoplot/tmp/slurm/%j.out
#SBATCH --error=results/0022_QC_of_nanopore_fastq_by_nanoplot/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
###############################################################################
## step-01: preparation
    pipeline=0022_QC_of_nanopore_fastq_by_nanoplot
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fastq_file_path=$(grep "my_fastq_path" $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC
    cpus=$SLURM_CPUS_PER_TASK
    
###############################################################################
	log "STARTED : $pipeline --------------------------------"
###############################################################################
## run nanoplot
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate nanoplot_v1.41.3
    
    for i in $(cat $sublist ); do
        if [ ! -f $raw_files/$i/NanoStats.txt ] ; then
            log "STARTED : Nanoplot for $i"
            if [ -f $fastq_file_path/$i.fastq.gz ] ; then 
                NanoPlot \
                -t $SLURM_CPUS_PER_TASK \
                --fastq $fastq_file_path/$i.fastq.gz \
                -o $raw_files/$i

                elif [ -f $fastq_file_path/$i.fastq ] ; then 
                NanoPlot \
                -t $SLURM_CPUS_PER_TASK \
                --fastq $fastq_file_path/$i.fastq \
                -o $raw_files/$i
            fi
            else
            log "ALREADY FINISHED : Nanoplot for $i"
        fi
    done

###############################################################################
	log "ENDED :$pipeline --------------------------------" && clean
###############################################################################