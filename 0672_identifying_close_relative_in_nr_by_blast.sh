#!/bin/bash
###############################################################################
## header
    pipeline=0672_identifying_close_relative_in_nr_by_blast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline --------------------------------------"
###############################################################################
## preparation
    fasta_dir=$(grep "my_fasta_dir" $parameters | awk '{print $NF}')
    ls $fasta_dir/ | sed 's/.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
    
    rm $list
###############################################################################