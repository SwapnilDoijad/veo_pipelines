#!/bin/bash
###############################################################################
## header
    pipeline=0086_annotation_prophage_by_phold
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ------------------------"
###############################################################################
## step-01: file preparations
    gbk_dir=$(grep "my_gbk_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
    ls $gbk_dir/ | sed 's/.gbk//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
    
###############################################################################
## footer
    log "ENDED : $pipeline ------------------------"
###############################################################################
