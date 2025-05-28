#!/bin/bash
###############################################################################
## header 
    pipeline=0492_contig_mapping_by_ragtag
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"
###############################################################################
## step-01: preparation

    create_directories_structure_1 $wd

    awk '/query_ids/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/filepath.txt
    list=$wd/tmp/filepath.txt

    split_list $wd $list
    submit_jobs $wd $pipeline
    mkdir -p $wd/all_fasta
###############################################################################
## footer
    log "ENDED : $pipeline ----------------------"
###############################################################################