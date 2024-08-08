#!/bin/bash
###############################################################################
## header
    pipeline=0072_QC_of_contigs_by_checkV
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline -----------------------------------"
###############################################################################
## step-01: preparation

    ls $fasta_dir_path/*.fasta | awk -F'/' '{print $NF}' | sed 's/.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
    # rm list.$pipeline.txt
    echo "ENDED : $pipeline ----------------------"
###############################################################################