#!/bin/bash
#SBATCH --job-name 0083_annotation_prophage_by_pharokka
#SBATCH --partition=short,interactive,standard,long,gpu
#SBATCH --output results/0083_annotation_prophage_by_pharokka/tmp/slurm/%j.out
#SBATCH --error results/0083_annotation_prophage_by_pharokka/tmp/slurm/%j.err
#SBATCH --cpus-per-task=80
###############################################################################
## 00: preparations
    pipeline=0083_annotation_prophage_by_pharokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_path=$(grep "my_fasta_path" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run pharokka
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate pharokka_v1.2.1

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/$i.gbk ]; then
			log "STARTED : $pipeline : $i"

            pharokka.py \
            -i $fasta_path/$i.fasta \
            -o $wd/raw_files/$i \
            -d /work/groups/VEO/databases/pharokka/v20230501 \
            -t $SLURM_CPUS_PER_TASK \
            -p $i

			log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist"
###############################################################################