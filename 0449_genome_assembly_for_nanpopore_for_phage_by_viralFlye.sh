#!/bin/bash
###############################################################################
## header 

    pipeline=0449_genome_assembly_for_nanpopore_for_phage_by_viralFlye
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"

###############################################################################
## step-01: preparation
	# list=list.fastq.2.txt
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
#######################################################################
## footer
    log "ENDED : $pipeline ----------------------"
###############################################################################
