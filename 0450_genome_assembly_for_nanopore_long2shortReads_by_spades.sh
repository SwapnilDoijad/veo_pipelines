#!/bin/bash
###############################################################################
## header 
	pipeline=0450_genome_assembly_for_nanopore_long2shortReads_by_spades
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
###############################################################################
## step-00: preparation	
    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		read l
		list=$(echo "list.$l.txt")
	fi

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
## footer
	log "FINISHED : $pipeline ------------------------"
###############################################################################
