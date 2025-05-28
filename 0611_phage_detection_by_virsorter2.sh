#!/bin/bash
###############################################################################
## header
    pipeline=0611_phage_detection_by_virsorter2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
	fasta_dir_path=$(grep "my_fasta_path" $parameters | awk '{print $2}')
    ls $fasta_dir_path/*.fasta | awk -F'/' '{print $NF}' | sed 's/.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
    log "STARTED : $pipeline ---------------------------------"
###############################################################################

