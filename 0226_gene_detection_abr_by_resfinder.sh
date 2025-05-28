#!/bin/bash
###############################################################################
## header
    pipeline=0226_gene_detection_abr_by_resfinder
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED SUBMISSION: $pipeline "
###############################################################################
## step-01: file and directory preparation
    fasta_directory=$( grep my_fasta_dir  $parameters | awk '{print $2}' )
    ls $fasta_directory | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
## footer
    log "ENDED: $pipeline "
###############################################################################
