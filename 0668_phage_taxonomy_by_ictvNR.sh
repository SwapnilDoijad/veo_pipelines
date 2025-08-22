#!/bin/bash
###############################################################################
## header
    pipeline=0668_phage_taxonomy_by_ictvNR
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    # fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    # ls $fasta_directory | sed 's/\.fasta$//' > list.$pipeline.txt
    # list=list.$pipeline.txt

    create_directories_structure_1 $wd
    # split_list $wd $list
    # submit_jobs $wd $pipeline

    cp /home/groups/VEO/scripts_for_users/supplementary_scripts/0668_phage_taxonomy_by_ictvNR.sbatch \
    $wd/tmp/sbatch/
    sbatch $wd/tmp/sbatch/0668_phage_taxonomy_by_ictvNR.sbatch

###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################