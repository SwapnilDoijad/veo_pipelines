#!/bin/bash
#SBATCH --job-name=0552_genome_assembly_comparison_by_quast
#SBATCH --partition=gpu-veo,gpu,gpu-test,standard,long
#SBATCH --output=results/0552_genome_assembly_comparison_by_quast/tmp/slurm/%j.out
#SBATCH --error=results/0552_genome_assembly_comparison_by_quast/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################

pipeline=0552_genome_assembly_comparison_by_quast
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
fasta_path=$(grep "my_fasta_path" $parameters | awk '{print $2}' )

        log "STARTED: $pipeline"

        python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py \
        -o $raw_files/ \
        --silent -t $SLURM_CPUS_PER_TASK \
        "$fasta_path"/* \
        & my_pid=$!
        
        get_resource_stat $my_pid $wd/tmp/resource_log/$id.quast.tsv

        log "FINISHED: $pipeline"

###############################################################################