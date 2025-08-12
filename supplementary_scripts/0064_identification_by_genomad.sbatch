#!/bin/bash
#SBATCH --job-name 0064_identification_by_genomad
#SBATCH --partition=standard
#SBATCH --output results/0064_identification_by_genomad/tmp/slurm/%j.0064_identification_by_genomad.out
#SBATCH --error results/0064_identification_by_genomad/tmp/slurm/%j.0064_identification_by_genomad.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## 01: preparation
    pipeline=0064_identification_by_genomad
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_file_path=$(grep "my_fasta_path" tmp/parameters/$pipeline.* | awk '{print $2}')
    task=$(grep "my_task" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
## 02: run genomad
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
    conda activate genNomad_v20230721

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/"$i"_summary.log ]; then 
            log "STARTED : $pipeline : $i"

            ( mkdir $wd/raw_files/$i ) > /dev/null 2>&1

            if [ $task == "end-to-end" ]; then

                genomad $task \
                -t $SLURM_CPUS_PER_TASK \
                --cleanup \
                --splits 8 \
                $fasta_file_path/$i.fasta \
                $wd/raw_files/$i \
                /veodata/03/databases/geNomad/v1.3 \
                & my_pid=$!
                get_resource_stat $my_pid $resource_log/$i.genomad.$task.tsv

            elif [ $task != "end-to-end" ]; then

                log "STARTED : $pipeline : $i with task $task"

                genomad $task \
                -t $SLURM_CPUS_PER_TASK \
                --cleanup \
                $fasta_file_path/$i.fasta \
                $wd/raw_files/$i \
                & my_pid=$!
                get_resource_stat $my_pid $resource_log/$i.genomad.$task.tsv

            else
                log "ERROR : $pipeline : $i - Invalid task specified"
                exit 1
            fi
        else
        log "ALREADY FINISHED : $pipeline : $i"
        fi
	done
###############################################################################
    log "FINISHED : $pipeline for $sublist" && clean
###############################################################################