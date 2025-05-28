#!/bin/bash
#SBATCH --job-name=0085_annotation_bateria_by_bakta
#SBATCH --partition=short,long,standard
#SBATCH --output=results/0085_annotation_bateria_by_bakta/tmp/slurm/%j.out
#SBATCH --error=results/0085_annotation_bateria_by_bakta/tmp/slurm/%j.err
#SBATCH --cpus-per-task=80
#SBATCH --mem=100G
###############################################################################
## 00: preparations
    pipeline=0085_annotation_bateria_by_bakta
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_path=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run bakta
    conda activate bakta_v1.9.3

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/$i.gbk ]; then
			log "STARTED : $pipeline : $i"

            bakta \
            --db /veodata/03/databases/bakta/v20240516/db \
            -p $i \
            -o $wd/raw_files/$i \
            -t $SLURM_CPUS_PER_TASK \
            $fasta_path/$i.fasta \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.bakta.tsv 

            python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/bakta_to_prokka_gff.py \
            -i $wd/raw_files/$i/$i.gff3 \
            -o $wd/raw_files/$i/$i.gff3.cleaned_for_panaroo
            
			log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist"
###############################################################################