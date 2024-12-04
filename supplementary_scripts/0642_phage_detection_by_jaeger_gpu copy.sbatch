#!/bin/bash
###############################################################################
#SBATCH --job-name 0642_phage_detection_by_jaeger_gpu.v20230903
#SBATCH --partition=gpu
#SBATCH --output results/0642_phage_detection_by_jaeger_gpu/tmp/slurm/%j.out
#SBATCH --error results/0642_phage_detection_by_jaeger_gpu/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
###############################################################################
## step-01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0642_phage_detection_by_jaeger_gpu
    sublist=$wd/tmp/lists/ABC

    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate jaeger_v1.1.30a0
    module load nvidia/cuda/11.7 
###############################################################################
## step-02: main command

    log "STARTED : $pipeline : sbatch for $sublist"

    for i in $(cat $sublist); do 
        if [ ! -f $wd/raw_files/$i.contigs_jaeger.tsv ] ; then
            log "STARTED : $pipeline : sbatch for $sublist : $i "

            export TF_CPP_MIN_LOG_LEVEL=3
            fasta_path=$(grep $i tmp/parameters/$pipeline.txt )

            /usr/bin/time -v -o $wd/logs/${i}_time.log Jaeger \
            -i $fasta_path \
            -o $wd/raw_files/ \
            --batch 40

            log "FINISHED : $pipeline : sbatch for $sublist : $i "
            else
            log "ALREADY FINISHED : $pipeline : sbatch for $sublist : $i "
        fi 
    done 

exit
###############################################################################
## step-03: post-processing

    for i in $(cat $sublist); do 
        awk -F'\t' '$7=="Phage" {print $0}' $wd/raw_files/$i.contigs_jaeger.tsv \
        > $wd/raw_files/$i.contigs_jaeger.tsv.phage.tsv 
        phage_count=$( wc -l $wd/raw_files/$i.contigs_jaeger.tsv.phage.tsv | awk '{print $1}' )
        echo -e "$i\t$phage_count" | tee -a $wd/phage_count.tsv
    done

    for i in $(cat $sublist); do
        if [ ! -f $wd/extracted_fasta/$i/$i.phage.fasta ] ; then 
            log "STARTED : $pipeline : extracting fasta for $i"
            mkdir -p $wd/extracted_fasta/$i
            fasta_path=$(grep $i tmp/parameters/$pipeline.txt )

            awk '{print $1}' $wd/raw_files/$i.contigs_jaeger.tsv.phage.tsv \
            > $wd/raw_files/$i.contigs_jaeger.tsv.phage.list

            /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl \
            -X \
            -f $wd/raw_files/$i.contigs_jaeger.tsv.phage.list \
            $fasta_path \
            > $wd/extracted_fasta/$i/$i.phage.fasta
            

            sed -i "s/>/>$i/g" $wd/extracted_fasta/$i/$i.phage.fasta
            sed -i "s/ /_/g" $wd/extracted_fasta/$i/$i.phage.fasta

            log "FINISHED : $pipeline : extracting fasta for $i"
            else
            log "ALREADY FINISHED : $pipeline : extract fasta for $i"
        fi 
    done

    for i in $(cat $sublist); do
        if [ ! -d $wd/extracted_fasta_split_all ] ; then 
            log "STARTED : $pipeline : $i : split fasta step "
            mkdir -p $wd/extracted_fasta_split/$i
            mkdir -p $wd/extracted_fasta_split_all

            bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
            -i $wd/extracted_fasta/$i/$i.phage.fasta \
            -o $wd/extracted_fasta_split/$i 

            bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
            -i $wd/extracted_fasta/$i/$i.phage.fasta \
            -o $wd/extracted_fasta_split_all
            else
            log "ALREADY FINISHED : $pipeline : $i : split fasta step "
        fi
    done

###############################################################################


# /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl -X \
# -f results/0642_phage_detection_by_jaeger_gpu/raw_files/zr11465-08.contigs_jaeger.tsv.phage.list \
# results/0055_metagenome_assembly_by_megahit_for_illumina/all_fasta/zr11465-08.contigs.fasta \
# > results/0642_phage_detection_by_jaeger_gpu/extracted_fasta/zr11465-08.phage.fasta
