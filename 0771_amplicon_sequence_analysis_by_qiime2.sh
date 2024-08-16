#!/bin/bash
###############################################################################
## header
    pipeline=0771_amplicon_sequence_analysis_by_qiime2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline --------------------------------------"
###############################################################################
## preparation

    create_directories_structure_1 $wd
    submit_jobs $wd $pipeline
    
    echo "ENDED : $pipeline --------------------------------------"
###############################################################################