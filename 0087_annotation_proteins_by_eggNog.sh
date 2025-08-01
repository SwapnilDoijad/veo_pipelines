#!/bin/bash
###############################################################################
## header
    pipeline=0087_annotation_proteins_by_eggNog
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ------------------------"
###############################################################################
## step-01: file preparations
    faa_dir=$(grep "my_faa_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
    ls $faa_dir/ | sed 's/.faa//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
    
###############################################################################
## footer
    log "ENDED : $pipeline ------------------------"
###############################################################################
