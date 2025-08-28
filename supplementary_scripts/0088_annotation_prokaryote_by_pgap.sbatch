#!/bin/bash
#SBATCH --job-name=0088_annotation_prokaryote_by_pgap
#SBATCH --partition=gpu,gpu-test,gpu-veo,standard,long
#SBATCH --output=results/0088_annotation_prokaryote_by_pgap/tmp/slurm/%j.out
#SBATCH --error=results/0088_annotation_prokaryote_by_pgap/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
## 00: preparations
    pipeline=0088_annotation_prokaryote_by_pgap
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_dir=$(grep "my_fasta_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
    organism=$(grep "my_organism" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run phold
    source /home/groups/VEO/tools/pgap/v2025-05-06.build7983/pgap-env/bin/activate
    export PGAP_INPUT_DIR=/veodata/03/databases/pgap/
    for i in $(cat $sublist); do
        log "STARTED : $pipeline : $i"

        ## cpus: by default will use maxiumum available CPUS.
        python /home/groups/VEO/tools/pgap/v2025-05-06.build7983/pgap/scripts/pgap.py \
        --container-path /home/groups/VEO/tools/pgap/v2025-05-06.build7983/pgap_2025-05-06.build7983.sif \
        --no-internet \
        --no-self-update \
        -g $fasta_dir/$i.fasta \
        -s $organism \
        --prefix $i \
        -n \
        -o $raw_files/$i \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$i.pgap.tsv 
        
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist" && clean
###############################################################################



