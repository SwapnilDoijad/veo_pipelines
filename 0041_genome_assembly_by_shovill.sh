#!/bin/bash
###############################################################################
    pipeline=0041_genome_assembly_by_shovill
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -------------------------------------"
###############################################################################
## step-01: preparations

    list=list.fastq.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
