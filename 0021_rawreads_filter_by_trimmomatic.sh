#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0021_rawreads_filter_by_trimmomatic ---------------------------------"
###############################################################################
## step-01: file and directory preparation

    pipeline=0021_rawreads_filter_by_trimmomatic
    wd=results/$pipeline

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
## step-01: preparations

    # if [ -f list.fastq.txt ]; then 
    #     list=list.fastq.txt
    #     else
    #     echo "provide list file (for e.g. all)"
    #     ls list.*.txt | sed 's/ /\n/g'
    #     read l
    #     list=$(echo "list.$l.txt")
    # fi
     
    # if [ -f result_summary.read_me.txt ]; then
    #     fastq_file_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')
    #     else
    #     echo "provide fastq_file_path"
    #     read fastq_file_path
    # fi

    # (mkdir -p results/0021_filter_reads_by_trimmomatic) > /dev/null 2>&1
###############################################################################
# FILE-CHECK--------------------------------------------------------------------

    # for F1 in $(cat $list); do

    #     if [ ! -f results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R1_001.filtered_paired.fastq.gz ]; then
    #     echo "filtering reads for $F1 failed" 
    #     echo "filtering reads for $F1 failed" >> results/failed_list.txt
    #     fi

    #     if [ ! -f results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R2_001.filtered_paired.fastq.gz ]; then
    #     echo "filtering reads for $F1 failed" 
    #     echo "filtering reads for $F1 failed" >> results/failed_list.txt
    #     fi

    # done

###############################################################################
echo "script 0021_filter_rawreads ended ----------------------------------------------"
###############################################################################
