#!/bin/bash
#SBATCH --job-name 0085_annotation_bateria_by_bakta
#SBATCH --partition=my_partition
#SBATCH --output results/0085_annotation_bateria_by_bakta/tmp/slurm/%j.out
#SBATCH --error  results/0085_annotation_bateria_by_bakta/tmp/slurm/%j.err
#SBATCH --cpus-per-task=80
###############################################################################
## 00: preparations
    pipeline=0085_annotation_bateria_by_bakta
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_path=$(grep "my_fasta_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run bakta
    conda activate bakta_v1.9.3

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/$i.gbk ]; then
			log "STARTED : $pipeline : $i"

            bakta \
            --db /work/groups/VEO/databases/bakta/v20240516/db \
            -p $i \
            -o $wd/raw_files/$i \
            -t $SLURM_CPUS_PER_TASK \
            --skip-plot \
            $fasta_path/$i.fasta

			log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist"
###############################################################################