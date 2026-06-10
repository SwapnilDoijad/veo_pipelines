#!/bin/bash
###############################################################################
## header
    pipeline=0774_amplicon_sequence_analysis_for_nanopore_by_EMU
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    basename -a $fasta_directory/*.fasta | sed 's/\.fasta$//' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd

    mkdir $raw_files/distribution
    mkdir $raw_files/abundance
    
    split_list $wd $list
    submit_jobs $wd $pipeline


###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################