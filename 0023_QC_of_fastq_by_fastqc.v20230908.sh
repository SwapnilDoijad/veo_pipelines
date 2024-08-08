#!/bin/bash
###############################################################################
## header
    pipeline=0023_QC_by_fastqc
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline -----------------------------------------------"
###############################################################################

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
        else
        echo "provide list file (for e.g. all)"
        ls list.*.txt | sed 's/ /\n/g'
        read l
        list=$(echo "list.$l.txt")
    fi

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
## step-02: fastqc 


###############################################################################
echo "script 0023_QC_by_fastqc ended -------------------------------------------------"
###############################################################################