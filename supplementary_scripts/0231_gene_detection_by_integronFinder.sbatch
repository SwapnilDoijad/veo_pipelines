#!/bin/bash
#SBATCH --job-name=0231_gene_detection_by_integronFinder
#SBATCH --partition=standard,long,gpu,gpu-veo,gpu-test
#SBATCH --output=results/0231_gene_detection_by_integronFinder/tmp/slurm/%j.out
#SBATCH --error=results/0231_gene_detection_by_integronFinder/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=50G
###############################################################################
## step-01: preparation
    pipeline=0231_gene_detection_by_integronFinder
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    sublist=$wd/tmp/lists/ABC

    source /home/groups/VEO/tools/integronFinder_v2.0.2/integronFinder_v2.0.2_VENV/bin/activate

###############################################################################
    log "STARTED : $pipeline" 
###############################################################################

    for i in $(cat $sublist); do

        setsid \
        integron_finder \
        --local-max \
        --func-annot \
        --cpu 40 \
        --outdir ${raw_files}/$i \
        --cmsearch /home/groups/VEO/tools/infernal/v1.1.5/src/cmsearch \
        --hmmsearch /home/groups/VEO/tools/hmmer/v3.3.1/bin/hmmsearch \
        --prodigal /home/groups/VEO/tools/prodigal/v2.6.3/prodigal \
        ${fasta_dir}/${i}.fasta \
        & my_pid=$!
        pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
        accurate_log_usage_by_pgid "$pgid" $wd/tmp/resource_log/$i.tsv 1

    done 

###############################################################################
    log "FINISHED : $pipeline" && clean
###############################################################################
