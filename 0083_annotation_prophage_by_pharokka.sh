#!/bin/bash
###############################################################################
## header
    pipeline=0083_annotation_prophage_by_pharokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0083_annotation_prophage_by_pharokka ------------------------"
###############################################################################
## step-01: file preparations

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
        sfx=$(echo "_$l")
    fi

    if [ -f result_summary.read_me.txt ]; then
        fasta_path=$(grep "fasta" result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi 

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
## step-02: running pharokka

    # echo -e "ID\tnumber of CDS" > $wd/summary.tsv
    # for i in $(cat $list); do 
    #     while [ ! -f "$wd/raw_files/$i/phanotate.faa" ]; do
    #         log "WAITING : pharokka to finish $i"
    #         sleep 60
    #     done
    #     log "FINISHED : pharokka for $i"
    #     CDS=$(grep -c ">" "$wd/raw_files/$i/phanotate.faa")
    #     echo -e "$i\t$CDS" >> "$wd/summary.tsv"
    # done 

###############################################################################
## footer
    log "ENDED : 0083_annotation_prophage_by_pharokka ------------------------"
###############################################################################
