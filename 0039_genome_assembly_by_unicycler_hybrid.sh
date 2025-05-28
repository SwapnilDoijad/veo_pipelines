#!/bin/bash
###############################################################################
## header
	pipeline=0039_genome_assembly_by_unicycler_hybrid
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : $pipeline started ------------------------------------"
###############################################################################
## step-01: preparation

	awk '/## long_read/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > list.$pipeline.txt
	list=list.$pipeline.txt

    create_directories_structure_1 $wd
	split -d -a 3 -l 1 "$list" "$wd/tmp/lists/list.$pipeline"_
    # split_list $wd $list
    submit_jobs $wd $pipeline

	mkdir -p $wd/all_fasta > /dev/null 2>&1
###############################################################################
	log "ENDED : $pipeline ended --------------------------------------"
###############################################################################


