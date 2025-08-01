#!/bin/bash
#SBATCH --job-name 0083_annotation_prophage_by_pharokka
#SBATCH --partition=standard,long,gpu
#SBATCH --output results/0083_annotation_prophage_by_pharokka/tmp/slurm/%j.out
#SBATCH --error results/0083_annotation_prophage_by_pharokka/tmp/slurm/%j.err
#SBATCH --cpus-per-task=80
###############################################################################
## 00: preparations
    pipeline=0083_annotation_prophage_by_pharokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run pharokka
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate pharokka_v1.2.1

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/$i.gbk ]; then
			log "STARTED : $pipeline : $i"

            id=$(echo $i | cut -f 1 -d '_')

            pharokka.py \
            -i $fasta_directory/$i.fasta \
            -o $raw_files/$i \
            -d /veodata/03/databases/pharokka/v20230501 \
            -t $SLURM_CPUS_PER_TASK \
            -f -p $i -l $id \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.pharokka.tsv 

			log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist"
###############################################################################