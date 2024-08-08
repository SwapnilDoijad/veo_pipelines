#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0136_phylogeny_by_fastANI_for_specific_fasta -----------------------------------"
###############################################################################
## step-00: preparation
    pipeline=0136_phylogeny_by_fastANI_for_specific_fasta
    wd=results/$pipeline

    create_directories_structure_1 $wd


    parameter_file=tmp/parameters/$pipeline.*
    fasta_path=$(grep -v "#" $parameter_file > $wd/tmp/list.fasta_including_path.txt )
    list=$wd/tmp/list.fasta_including_path.txt

    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
