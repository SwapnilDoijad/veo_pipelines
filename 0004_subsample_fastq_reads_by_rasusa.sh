#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0004_subsample_fastq_reads_by_rasusa ---------------------------------"
###############################################################################
## step-01: file and directory preparation

    pipeline=0004_subsample_fastq_reads_by_rasusa
    wd=results/$pipeline

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
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
    echo "STARTED : 0004_subsample_fastq_reads_by_rasusa ---------------------------------"
###############################################################################