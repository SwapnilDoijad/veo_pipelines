#!/bin/bash
###############################################################################
#SBATCH --job-name 0644_phage_detection_by_jaeger-gpu-parallel.v20230903
#SBATCH --partition=gpu
#SBATCH --output results/0644_phage_detection_by_jaeger-gpu-parallel/tmp/slurm/%j.out
#SBATCH --error results/0644_phage_detection_by_jaeger-gpu-parallel/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
###############################################################################
## step-01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0644_phage_detection_by_jaeger-gpu-parallel
    wd=results/$pipeline

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate jaeger_v1.31.0
    module load nvidia/cuda/11.7 
###############################################################################
## step-02: main command

        log "STARTED : $pipeline : sbatch for $sublist"

        python /home/groups/VEO/tools/jaeger/v1.1.23_parallel/bin/Jaeger_parallel \
        -i $wd/tmp/$pipeline.csv \
        -o $wd/raw_files/

        log "ENDED : $pipeline : sbatch for $sublist"

###############################################################################
## step-03: post-processing

    for i in $(cat $list); do 
        awk -F'\t' '$7=="Phage" {print $0}' $wd/raw_files/$i.contigs_jaeger.tsv \
        > $wd/raw_files/$i.contigs_jaeger.tsv.phage.tsv 
    done

###############################################################################
