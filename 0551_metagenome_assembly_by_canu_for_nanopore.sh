#!/bin/bash
###############################################################################
## header 
	pipeline=0551_metagenome_assembly_by_canu_for_nanopore
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
###############################################################################
## step-00: preparation	

	fastq_path=$( grep my_fastq $parameters | awk '{print $2}' )
	ls $fastq_path/ | sed 's/\.fastq\.gz//g' > list.$pipeline.txt
	list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
## footer
	log "FINISHED : $pipeline ------------------------"
###############################################################################
