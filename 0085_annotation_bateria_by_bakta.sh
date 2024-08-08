#!/bin/bash
###############################################################################
## header
    pipeline=0085_annotation_bateria_by_bakta
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ------------------------"
###############################################################################
## step-01: file preparations
    fasta_dir=$(grep "my_fasta_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
    ls $fasta_dir/ | sed 's/.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
    
    rm list.$pipeline.txt
###############################################################################
## footer
    log "ENDED : $pipeline ------------------------"
###############################################################################
