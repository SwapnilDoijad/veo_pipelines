#!/bin/bash
#SBATCH --job-name=0081_annotation_bacteria_by_prokka
#SBATCH --partition=gpu,gpu-test,gpu-veo,standard,long
#SBATCH --output=results/0081_annotation_bacteria_by_prokka/tmp/slurm/%j.out
#SBATCH --error=results/0081_annotation_bacteria_by_prokka/tmp/slurm/%j.err
#SBATCH --mem=40G
#SBATCH --cpus-per-task=40
###############################################################################
    pipeline=0081_annotation_bacteria_by_prokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file_dir=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate prokka_v1.14.6
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
    for F1 in $(cat $sublist); do
        if [ ! -f $raw_files/$F1/$F1.gbk ]; then
            echo "annotating $F1"
            (mkdir $raw_files/$F1) > /dev/null 2>&1
            (mkdir $raw_files/$F1/tmp) > /dev/null 2>&1
                    
            prokka \
            --quiet \
            --outdir $raw_files/$F1 \
            --force \
            --prefix $F1 \
            --kingdom Bacteria \
            --addgenes \
            --locustag $F1 \
            --cpus $SLURM_CPUS_PER_TASK \
            --fast \
            --rnammer $fasta_file_dir/"$F1".fna \
            & my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$id.prokka.tsv 

            else
            echo "annotation of $F1 alredy finished"
        fi
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist" && clean
###############################################################################
