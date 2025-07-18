#!/bin/bash
#SBATCH --job-name=0060_metagenome_assembly_QC_by_metaquast
#SBATCH --partition=interactive
#SBATCH --output=results/0060_metagenome_assembly_QC_by_metaquast/tmp/slurm/%j.out
#SBATCH --error=results/0060_metagenome_assembly_QC_by_metaquast/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=20
###############################################################################
## step-00: preparation
    pipeline=0060_metagenome_assembly_QC_by_metaquast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    
###############################################################################
	log "STARTED : $pipeline for $sublist"
###############################################################################

    python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
    -o results/0060_QC_genome-metagenome_assembly_by_metaquast/results/$i \
    results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta/$i/* 

###############################################################################
	log "finished : $pipeline for $sublist" && clean
###############################################################################