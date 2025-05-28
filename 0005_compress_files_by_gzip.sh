#!/bin/bash
###############################################################################
## step-00: tools, databases, paths, inputs and outputs
    pipeline=0005_compress_files_by_gzip
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
log "STARTED: $pipeline started --------------------------------------------"
###############################################################################
    in_dir=$(grep my_uncompressed_file_dir $parameters | awk '{print $2}')

    ls $in_dir | grep -v ".gz" > list.files.txt
    list=list.files.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
log "ENDED: $pipeline -------------------------------------------------------"
###############################################################################