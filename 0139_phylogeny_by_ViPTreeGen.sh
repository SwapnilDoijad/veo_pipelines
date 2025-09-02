#!/bin/bash
###############################################################################
## header
    pipeline=0139_phylogeny_by_ViPTreeGen
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED SUBMISSION: $pipeline "
###############################################################################
## step-01: file and directory preparation
    fasta_file=$( grep my_fasta_file $parameters | awk '{print $2}' )
    basename -a $fasta_file > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
## footer
    log "ENDED: $pipeline "
###############################################################################

