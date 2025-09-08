#!/bin/bash
#SBATCH --job-name 0083_annotation_prophage_by_pharokka
#SBATCH --partition=standard,long,gpu
#SBATCH --output results/0083_annotation_prophage_by_pharokka/tmp/slurm/%j.out
#SBATCH --error results/0083_annotation_prophage_by_pharokka/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=200G
###############################################################################
## 00: preparations
    pipeline=0083_annotation_prophage_by_pharokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    mode=$( grep my_mode $parameters | awk '{print $2}' )
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist : $mode"
###############################################################################
## 01: run pharokka
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate pharokka_v1.7.2

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/$i.gbk ]; then
			log "STARTED : $pipeline : $mode : $i "

            # id=$(echo $i | cut -f 1 -d '_')
            ## Note that, if you use id then NC_0056677 wil get to NC_
            ## and then all cds will have NC_001, NC_002, ...
            ## which will be a problem for downstream analysis

            if [ $mode == "normal" ]; then

                pharokka.py \
                -i $fasta_directory/$i.fasta \
                -o $raw_files/$i \
                -d /veodata/03/databases/pharokka/v1.7.1 \
                -t $SLURM_CPUS_PER_TASK \
                -f -p $i -l $i \
                & my_pid=$!
                get_resource_stat $my_pid $wd/tmp/resource_log/$i.pharokka.normal.tsv 

            elif [ $mode == "fast" ]; then
                pharokka.py \
                -i $fasta_directory/$i.fasta \
                -o $wd/raw_files/$i \
                -d /veodata/03/databases/pharokka/v1.7.1 \
                -t $SLURM_CPUS_PER_TASK \
                -g prodigal \
                --skip_extra_annotations \
                --skip_mash \
                & my_pid=$!
                get_resource_stat $my_pid $wd/tmp/resource_log/$i.pharokka.fast.tsv
            
            else
                log "ERROR: mode $mode is not supported. Please use 'normal' or 'fast'"
                exit 1
            fi
			log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist"
###############################################################################