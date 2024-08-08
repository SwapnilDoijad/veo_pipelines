#!/bin/bash
###############################################################################
## header 
	pipeline=0447_genome_assembly_for_phage_from_nanopore_reads_by_raven
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	echo "STARTED : $pipeline ---------------------------------"
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
	echo "FINISHED : $pipeline ---------------------------------"
###############################################################################

