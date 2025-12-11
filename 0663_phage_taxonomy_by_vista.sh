#!/bin/bash
###############################################################################
## header
    pipeline=0663_phage_taxonomy_by_vista
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    grep my_fasta_file $parameters | awk '{print $2}' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################