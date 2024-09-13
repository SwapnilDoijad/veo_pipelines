#!/bin/bash
###############################################################################
## header
    pipeline=0991_calculate_abundance_from_fastq
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline --------------------------------------"
###############################################################################
## preparation

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_calculate_abundance_from_fastq.sbatch
    
    echo "ENDED : $pipeline --------------------------------------"
###############################################################################