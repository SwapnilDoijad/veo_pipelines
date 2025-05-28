#!/bin/bash
###############################################################################
## header 
    pipeline=0413_find_reference_genome_by_referenceseeker
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"
###############################################################################
## step-01: preparation

    fasta_path=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    ls $fasta_path/ | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt
	
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

#######################################################################