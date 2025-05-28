#!/bin/bash
#SBATCH --job-name=0086_annotation_prophage_by_phold
#SBATCH --partition=gpu,gpu-test,gpu-veo
#SBATCH --output=results/0086_annotation_prophage_by_phold/tmp/slurm/%j.out
#SBATCH --error=results/0086_annotation_prophage_by_phold/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=24
#SBATCH --mem=50G
###############################################################################
## 00: preparations
    pipeline=0086_annotation_prophage_by_phold
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    gbk_dir=$(grep "my_gbk_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run phold

    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    # conda activate pholdENV_v0.2.0_gpu
    conda activate pholdENV_240607 
    export PHOLD_DB_DIR=/veodata/03/databases/phold/v250331

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/$i.gbk ]; then
			log "STARTED : $pipeline : $i"

            ## gpu mode
            phold run \
            -i $gbk_dir/$i.gbk \
            -o $raw_files/$i \
            -t $SLURM_CPUS_PER_TASK \
            -p $i \
            -d /veodata/03/databases/phold/v240724/ \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.phold.gpu.tsv 

            ## cpu mode
                # phold run --cpu \
                # -i $gbk_dir/$i.gbk \
                # -o $raw_files/$i \
                # -t $SLURM_CPUS_PER_TASK \
                # -p $i \
                # -d /veodata/03/databases/phold/v240724/ \
                # & my_pid=$!
                # get_resource_stat $my_pid $wd/tmp/resource_log/$i.phold.cpu.tsv 
            
			log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist"
###############################################################################