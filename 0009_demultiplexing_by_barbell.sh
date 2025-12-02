#!/bin/bash
###############################################################################
## header
    pipeline=0009_demultiplexing_by_barbell
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline -----------------------------------------------"
###############################################################################

    primer_file=$(grep my_F_primer $parameters | awk '{print $2}')
    grep ">" $primer_file | sed 's/>//g' | awk -F'_' '{print $1}' | sort | uniq  > list.$pipeline.txt
    list=list.$pipeline.txt
	
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

    mkdir -p $wd/tmp/filters
    mkdir -p $wd/tmp/primers
    mkdir -p $wd/fastq
###############################################################################
    log "FINISHED : $pipeline -----------------------------------------------"
############################################################################---