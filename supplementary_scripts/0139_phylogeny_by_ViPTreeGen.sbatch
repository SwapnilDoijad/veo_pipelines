#!/bin/bash
#SBATCH --job-name=0139_phylogeny_by_ViPTreeGen
#SBATCH --partition=gpu,gpu-veo,gpu-test,standard,long
#SBATCH --output=results/0139_phylogeny_by_ViPTreeGen/tmp/slurm/%j.out
#SBATCH --error=results/0139_phylogeny_by_ViPTreeGen/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=50G
###############################################################################
## step-01: preparation
    pipeline=0139_phylogeny_by_ViPTreeGen
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file=$( grep my_fasta_file $parameters | awk '{print $2}' )

    export PATH=$PATH:/home/groups/VEO/tools/blast/v2.14.0/bin
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate ViPTreeGen_v1.1.3

    echo "fasta_file: $fasta_file"
###############################################################################
	log "STARTED : $pipeline" 
###############################################################################
## run ViPTreeGen

    $tools/ViPTreeGen/v1.1.3/ViPTreeGen/ViPTreeGen \
    $fasta_file \
    $raw_files/ViPTreeGen \
    & my_pid=$!
    get_resource_stat $my_pid $wd/tmp/resource_log/ViPTreeGen.tsv 

###############################################################################
	log "FINISHED : $pipeline" && clean
###############################################################################

