#!/bin/bash
###############################################################################
## header 
    pipeline=0493_genome_assembly_QC_by_inspector
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"
###############################################################################
## step-01: preparation

    create_directories_structure_1 $wd

    awk '/contigs/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/filepath.txt
    list=$wd/tmp/filepath.txt

    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
## footer
    log "ENDED : $pipeline ----------------------"
###############################################################################