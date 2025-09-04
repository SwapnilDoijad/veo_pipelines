#!/bin/bash
###############################################################################
## header
    pipeline=0851_genePlots_by_gggenomes
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    data_directory=$( grep my_data_dir $parameters | awk '{print $2}' )
    ls $data_directory | sed 's/\.fasta$//' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################