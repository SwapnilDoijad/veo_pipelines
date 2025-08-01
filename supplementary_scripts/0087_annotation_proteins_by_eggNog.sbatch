#!/bin/bash
#SBATCH --job-name=0087_annotation_proteins_by_eggNog
#SBATCH --partition=gpu,gpu-test,gpu-veo,standard,long
#SBATCH --output=results/0087_annotation_proteins_by_eggNog/tmp/slurm/%j.out
#SBATCH --error=results/0087_annotation_proteins_by_eggNog/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
## 00: preparations
    pipeline=0087_annotation_proteins_by_eggNog
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    faa_dir=$(grep "my_faa_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run phold

    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate emapper_v2.1.11_new

    for i in $(cat $sublist); do
        log "STARTED : $pipeline : $i"

        mkdir $raw_files/$i

        emapper.py \
        -i $faa_dir/$i.faa \
        -m diamond \
        --output $i \
        --output_dir $raw_files/$i \
        --data_dir /veodata/03/databases/emapper/v5.0.2/ \
        --cpu $SLURM_CPUS_PER_TASK \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$i.emapper.tsv

        grep -v "^#" $raw_files/$i/$i.emapper.annotations | cut -f1,12 | grep "ko:K"  | sed 's/ko://g' \
        > $raw_files/$i/$i.emapper.annotations.ko.tsv

        cut -f2 $raw_files/$i/$i.emapper.annotations.ko.tsv | tr ',' '\n' | sed 's/ko://' | sort | uniq \
        > $raw_files/$i/$i.kos_for_ipath.txt

    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist" && clean
###############################################################################



