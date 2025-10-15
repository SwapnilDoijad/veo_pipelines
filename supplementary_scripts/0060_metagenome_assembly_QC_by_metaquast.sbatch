#!/bin/bash
#SBATCH --job-name=0060_metagenome_assembly_QC_by_metaquast
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu,gpu-test
#SBATCH --output=results/0060_metagenome_assembly_QC_by_metaquast/tmp/slurm/%j.out
#SBATCH --error=results/0060_metagenome_assembly_QC_by_metaquast/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=20
###############################################################################
## step-00: preparation
    pipeline=0060_metagenome_assembly_QC_by_metaquast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file_dir=$(grep "my_fasta_directory" $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC

###############################################################################
	log "STARTED : $pipeline for $sublist"
###############################################################################

    for i in $(cat $sublist); do  
        log "started : $pipeline for $i"

        python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py \
        --silent \
        --circos \
        --threads $SLURM_CPUS_PER_TASK \
        -o $raw_files/$i \
        $fasta_file_dir/$i.fasta \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$i.tsv

    done
###############################################################################
	log "finished : $pipeline for $sublist" && clean
###############################################################################