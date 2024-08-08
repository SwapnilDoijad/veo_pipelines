#!/bin/bash
#SBATCH --job-name 0081_annotation_bacteria_by_prokka
#SBATCH --partition=short
#SBATCH --output results/0081_annotation_bacteria_by_prokka/tmp/slurm/%j.out
#SBATCH --error results/0081_annotation_bacteria_by_prokka/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
#-- Command section ------------------------
    pipeline=0081_annotation_bacteria_by_prokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file_dir=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate prokka_v1.14.6

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
            --addgenes \
            --locustag $F1 \
            --cpus 80 \
            --fast \
            --rnammer $fasta_file_dir/"$F1".fasta

            else
            echo "annotation of $F1 alredy finished"
        fi
    done
