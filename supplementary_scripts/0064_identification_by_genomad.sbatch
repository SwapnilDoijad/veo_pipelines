#!/bin/bash
#SBATCH --job-name 0064_identification_by_genomad
#SBATCH --partition=gpu
#SBATCH --output results/0064_identification_by_genomad/tmp/slurm/%j.0064_identification_by_genomad.out
#SBATCH --error results/0064_identification_by_genomad/tmp/slurm/%j.0064_identification_by_genomad.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## 01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0064_identification_by_genomad
    wd=results/$pipeline
    sublist=$wd/tmp/lists/ABC
    fasta_file_path=$(grep "my_fasta_path" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
## 02: run genomad
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate genNomad_v20230721

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/"$i"_summary.log ]; then 
            log "STARTED : $pipeline : $i"

            ( mkdir $wd/raw_files/$i ) > /dev/null 2>&1

            genomad end-to-end \
            -t 80 \
            --cleanup --splits 8 \
            $fasta_file_path/$i.fasta \
            $wd/raw_files/$i \
            /work/groups/VEO/databases/geNomad/v1.3

            log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
	done
###############################################################################