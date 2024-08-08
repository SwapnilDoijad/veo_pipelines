#!/bin/bash
###############################################################################
## header 
    pipeline=0452_genome_assembly_of_phage_polishing_by_phables
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"
###############################################################################
## step-01: preparation
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
#######################################################################
## footer
    log "ENDED : $pipeline ----------------------"
###############################################################################
