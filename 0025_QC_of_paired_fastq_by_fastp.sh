#!/bin/bash
###############################################################################
## header
    pipeline=0025_QC_of_paired_fastq_by_fastp
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline -----------------------------------"
###############################################################################
## step-01: preparation
    fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    ls $fastq_path/ | sed 's/\.fastq\.gz//g' | sed 's/_R1//g' | sed 's/_R2//g' | sort | uniq > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

    mkdir -p $wd/html
    echo -e "id\tf_reads\tr_reads\ttotal_reads\tfilt_f_reads\tfilt_r_reads\tfilt_total_reads" > $wd/stat.raw_read_count.tsv
###############################################################################
    echo "ENDED : $pipeline ----------------------"
###############################################################################