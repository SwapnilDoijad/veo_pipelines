#!/bin/bash
#SBATCH --job-name=0050_genome_assembly_QC_by_quast
#SBATCH --partition=short,standard,long,gpu,gpu-test,gpu-veo
#SBATCH --output=results/0050_genome_assembly_QC_by_quast/tmp/slurm/%j.out.0050_genome_assembly_QC_by_quast
#SBATCH --error=results/0050_genome_assembly_QC_by_quast/tmp/slurm/%j.err.0050_genome_assembly_QC_by_quast
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
###############################################################################
pipeline=0050_genome_assembly_QC_by_quast
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
fasta_directory=$(grep -w "my_fasta_directory" $parameters | awk -F'\t' '{print $2}')
result_choise=$(grep -w "my_result_choise" $parameters | awk -F'\t' '{print $2}')
###############################################################################
    log "STARTED : $pipeline for $sublist"
###############################################################################
    python3 $tools/quast/v5.2.0/quast.py \
    -o $raw_files \
    --silent \
    -t $SLURM_CPUS_PER_TASK \
    $fasta_directory/*.fasta
###############################################################################
	log "FINISHED : $pipeline for $sublist" && clean
###############################################################################