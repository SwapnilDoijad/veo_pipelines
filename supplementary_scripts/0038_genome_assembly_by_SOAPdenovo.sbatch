#!/bin/bash
#SBATCH --job-name=0038_genome_assembly_by_SOAPdenovo
#SBATCH --partition=standard,long,fat,gpu-veo,gpu,gpu-test
#SBATCH --output=results/0038_genome_assembly_by_SOAPdenovo/tmp/slurm/%j.out
#SBATCH --error=results/0038_genome_assembly_by_SOAPdenovo/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40 
###############################################################################
    pipeline=0038_genome_assembly_by_SOAPdenovo
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -------------------------------------"
###############################################################################
    sublist=$wd/tmp/lists/ABC
    fastq_path=$(grep my_fastq_path $parameters | awk '{print $2}')
    echo $fastq_path
###############################################################################
## step-01: run SOAPdenovo

    for i in $(cat $sublist); do
        log "STARTED: $pipeline for $i -------------------------------------"

        # setsid \
        # /home/groups/VEO/tools/SOAPdenovo2/v2.04/SOAPdenovo-127mer all \
        # -s $wd/tmp/parameters/$i.parameters \
        # -K 91 \
        # -R \
        # -o $raw_files/${i} \
        # -p 32 \
        # & my_pid=$!
        # pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
        # accurate_log_usage_by_pgid "$pgid" $resource_log/SOAPdenovo-127mer.tsv

        setsid \
        /home/groups/VEO/tools/SOAPdenovo2/v2.04/SOAPdenovo-127mer all \
        -s $wd/tmp/parameters/$i.parameters \
        -K 63 \
        -R \
        -o $raw_files/${i} \
        -p 32 \
        & my_pid=$!
        pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
        accurate_log_usage_by_pgid "$pgid" $resource_log/SOAPdenovo-127mer.tsv

        log "FINISHED : $pipeline for $i -------------------------------------"
    done

###############################################################################
	log "FINISHED : $pipeline for $sublist" && clean
###############################################################################