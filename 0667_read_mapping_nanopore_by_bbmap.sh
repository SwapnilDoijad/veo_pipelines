#!/bin/bash
echo "20240429 Swapnil, did not work for long reads"
exit
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0667_read_mapping_nanopore_by_bbmap ----------------------------------"
##############################################################################
## step-01: preparations
    pipeline=0667_read_mapping_nanopore_by_bbmap
    wd=results/$pipeline
    list=tmp/parameters/$pipeline.tsv

    grep -v "#" tmp/parameters/$pipeline.tsv > tmp/parameters/$pipeline.txt
    list=tmp/parameters/$pipeline.txt
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
## footer
    log "ENDED : 0065_read_mapping_by_minimap2 ----------------------------------"
###############################################################################