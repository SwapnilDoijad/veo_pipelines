#!/bin/bash
###############################################################################
## header
	pipeline=0542_metaVirome_assembly_by_megahit_for_Nanopore
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : $pipeline started ------------------------------------"
###############################################################################
## step-01: preparation

	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
	ls $fastq_path/ | sed 's/\.fastq\.gz//g' > list.fastq.$pipeline.txt
	list=list.fastq.$pipeline.txt

	echo -e "IDs\tnumber_of_contigs" > $summary.tsv

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
log "ENDED : $pipeline ended --------------------------------------"
###############################################################################


