#!/bin/bash
###############################################################################
## header
    pipeline=0083_annotation_prophage_by_pharokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0083_annotation_prophage_by_pharokka ------------------------"
###############################################################################
## step-01: file preparations
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    ls $fasta_directory | sed 's/.fasta//g' | sed 's/.fna//g' | sed 's/.fa//g' > list.$pipeline.txt
    list=list.$pipeline.txt

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
