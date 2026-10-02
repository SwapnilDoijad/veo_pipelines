#!/bin/bash
#SBATCH --job-name=0089_annotation_prokaryote_by_pharokkaPholdPhynteny
#SBATCH --partition=gpu,gpu-test,gpu-veo
#SBATCH --output=results/0089_annotation_prokaryote_by_pharokkaPholdPhynteny/tmp/slurm/%j.out
#SBATCH --error=results/0089_annotation_prokaryote_by_pharokkaPholdPhynteny/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=24
#SBATCH --mem=50G
###############################################################################
## 00: preparations
    pipeline=0089_annotation_prokaryote_by_pharokkaPholdPhynteny
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_dir=$(grep "my_fasta_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run pharokka
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate pharokka_v1.7.2
    rm -rf $wd/raw_files >& /dev/null
    mkdir -p $wd/pharokka

    for i in $(cat $sublist); do
        if [ ! -f $wd/pharokka/$i/$i.gbk ]; then
			log "STARTED : $pipeline : pharokka : $i "

            # id=$(echo $i | cut -f 1 -d '_')
            ## Note that, if you use id then NC_0056677 wil get to NC_
            ## and then all cds will have NC_001, NC_002, ...
            ## which will be a problem for downstream analysis

            pharokka.py \
            -i ${fasta_dir}/${i}.fasta \
            -o $wd/pharokka/$i \
            -d /veodata/03/databases/pharokka/v1.7.1 \
            -t $SLURM_CPUS_PER_TASK \
            -f -p $i -l $i \
            & my_pid=$!
            get_resource_stat $my_pid $wd/tmp/resource_log/$i.pharokka.normal.tsv 

            log "FINISHED : $pipeline : pharokka : $i"
            else
            log "ALREADY FINISHED : $pipeline : pharokka : $i"
        fi
    done
    conda deactivate
###############################################################################
## 02: run phold
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    conda activate pholdENV
    mkdir -p $wd/phold >& /dev/null
    export PHOLD_DB_DIR=/veodata/03/databases/phold/260407_v1.0.0/phold_db_3M16_v_1_0_0

    for i in $(cat $sublist); do
        if [ ! -f $wd/phold/$i/$i.gbk ]; then
			log "STARTED : $pipeline : phold : $i"

            ## gpu mode
            phold run \
            -i $wd/pharokka/$i/$i.gbk \
            -o $wd/phold/$i \
            -t $SLURM_CPUS_PER_TASK \
            -p $i \
            -d $PHOLD_DB_DIR \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.phold.gpu.tsv 

            ## plots
            phold plot \
            -i $wd/phold/$i/$i.gbk  \
            -o $wd/phold/$i/plots \
            -t $i

            python $suppl_scripts/utilities/gbk2gff.py \
            -i $wd/phold/$i/$i.gbk \
            -o $wd/phold/$i/$i.gff

			log "FINISHED : $pipeline : phold : $i"
            else
            log "ALREADY FINISHED : $pipeline : phold : $i"
        fi
    done
    conda deactivate
###############################################################################
## 03: run phynteny
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    conda activate phynteny_transformer_v0.1.3_gpu 
    export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
    mkdir -p $wd/phynteny >& /dev/null

    for i in $(cat $sublist); do
        if [ ! -f $wd/phynteny/$i/$i.gbk ]; then
            log "STARTED : $pipeline : phynteny : $i"

            phynteny_transformer \
            $wd/phold/$i/$i.gbk \
            -o $wd/phynteny/$i \
            --prefix $i \
            -m /vast/groups/VEO/tools/miniconda3_2024/envs/phynteny_transformer_v0.1.3_gpu/lib/python3.11/site-packages/phynteny_utils/models \
            --confidence-threshold 0.7 \
            -f \
            & my_pid=$!
            get_resource_stat $my_pid $wd/tmp/resource_log/$i.phynteny.tsv 

            log "FINISHED : $pipeline : phynteny : $i"
            else
            log "ALREADY FINISHED : $pipeline : phynteny : $i"
        fi
    done
    conda deactivate
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist"
###############################################################################