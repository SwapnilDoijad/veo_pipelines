#!/bin/bash
###############################################################################
## header
    pipeline=0025_QC_of_paired-fastq_by_fastp
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline -----------------------------------------------"
###############################################################################
## step-01: preparations

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

    echo -e "ID\tf_reads\tr_reads\ttotal_reads\tfilt_f_reads\tfilt_r_reads\tfilt_total_reads" > $wd/stat.raw_read_count.tsv

###############################################################################
    log "ENDED : $pipeline -----------------------------------------------"
###############################################################################