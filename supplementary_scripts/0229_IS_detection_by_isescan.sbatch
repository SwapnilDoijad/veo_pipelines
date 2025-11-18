#!/bin/bash
#SBATCH --job-name=0229_IS_detection_by_isescan
#SBATCH --partition=short,standard,long,interactive,gpu,gpu-veo,gpu-test
#SBATCH --output=results/0229_IS_detection_by_isescan/tmp/slurm/%j.out
#SBATCH --error=results/0229_IS_detection_by_isescan/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=50G
###############################################################################
## step-01: preparation
    pipeline=0229_IS_detection_by_isescan
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    sublist=$wd/tmp/lists/ABC

    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    conda activate isescan_v1.7.3
###############################################################################
    log "STARTED : $pipeline" 
###############################################################################
## step-02:

	for i in $(cat $sublist); do
        log "STARTING : $pipeline : $i"

        mkdir -p $raw_files/$i

        isescan.py \
        --seqfile $fasta_dir/$i.fasta \
        --output $raw_files/$i \
        --nthread $SLURM_CPUS_PER_TASK

    done

###############################################################################
    log "FINISHED : $pipeline" && clean
###############################################################################
