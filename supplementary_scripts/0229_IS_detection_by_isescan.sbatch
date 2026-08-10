#!/bin/bash
#SBATCH --job-name=0229_IS_detection_by_isescan
#SBATCH --partition=short,standard,long,interactive,gpu,gpu-veo,gpu-test
#SBATCH --output=results/0229_IS_detection_by_isescan/tmp/slurm/%A_%a.out
#SBATCH --error=results/0229_IS_detection_by_isescan/tmp/slurm/%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
###############################################################################
## step-01: preparation
    pipeline=0229_IS_detection_by_isescan
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )

    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    conda activate isescan_v1.7.3
    
    i=$(sed -n "${SLURM_ARRAY_TASK_ID}p" list.${pipeline}.txt)
###############################################################################
    log "STARTED : $pipeline" 
###############################################################################
## step-02:

        log "STARTING : $pipeline : $i"
        mkdir -p $raw_files/$i

        isescan.py \
        --seqfile ${fasta_dir}/${i}.fasta \
        --output ${raw_files}/${i} \
        --nthread ${SLURM_CPUS_PER_TASK}

        log "FINISHED : $pipeline : $i"

###############################################################################
    log "FINISHED : $pipeline" #&& clean
###############################################################################
