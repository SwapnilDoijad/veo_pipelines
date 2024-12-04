#!/bin/bash
#SBATCH --job-name 0552_genome_assembly_comparison_by_quast
#SBATCH --partition=gpu
#SBATCH --output results/0552_genome_assembly_comparison_by_quast/tmp/slurm/%j.out.0552_genome_assembly_comparison_by_quast
#SBATCH --error results/0552_genome_assembly_comparison_by_quast/tmp/slurm/%j.err.0552_genome_assembly_comparison_by_quast
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
#-- Command section ------------------------

pipeline=0552_genome_assembly_comparison_by_quast
wd=results/$pipeline
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

        # python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
        # -o $wd/raw_files_quast/ \
        # --silent -t 40 \
        # $wd/all_fasta/*

        python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py \
        -o $wd/raw_files_metaquast/ \
        --silent -t 40 \
        $wd/all_fasta/*