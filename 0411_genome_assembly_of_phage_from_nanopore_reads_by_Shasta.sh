#!/bin/bash
###############################################################################
## header
    pipeline=0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation

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
## footer
    log "FINISHED : $pipeline ---------------------------------"
###############################################################################