#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0666_read_mapping_illumina_by_bbmap ----------------------------------"
##############################################################################
## step-01: preparations
    echo "Hi Swpanil, do not parallelize this script. The reference is written in the same folder and thus if parallelized, it will overwrite the reference file and some samples will fail"
    echo "need to check if it is possible to write the reference file in a different folder"

    pipeline=0666_read_mapping_illumina_by_bbmap
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    grep -v "#" tmp/parameters/$pipeline.tsv > tmp/parameters/$pipeline.txt
    list=tmp/parameters/$pipeline.txt
    create_directories_structure_1 $wd
    submit_jobs $wd $pipeline

###############################################################################
## footer
    log "ENDED : 0065_read_mapping_by_minimap2 ----------------------------------"
###############################################################################