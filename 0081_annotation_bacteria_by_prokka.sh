#!/bin/bash
###############################################################################
# b08 annotation 
###############################################################################
echo "started... step-0081 annotation -------------------------------------------"
###############################################################################
## step-01: preparation
    pipeline=0081_annotation_bacteria_by_prokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    fasta_file_dir=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
    ls $fasta_file_dir | sed 's/\.fasta//g' | sed 's/\.fna//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

##############################################################################
echo "completed... step-08 annotation -----------------------------------------"
###############################################################################
