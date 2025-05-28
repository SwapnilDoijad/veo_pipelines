#!/bin/bash
###############################################################################
## header 
	pipeline=0445_genome_assembly_for_nanopore_for_phage_by_canu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
###############################################################################
## step-00: preparation	
    fastq_path=$( grep my_fastq_dir $parameters | awk '{print $2}' )
    ls $fastq_path/ | sed 's/\.fastq\.gz//g' > list.$pipeline.txt
    list=list.$pipeline.txt
	
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

	echo -e "id\tcontigs\tlength" > $wd/summary.tsv
###############################################################################
## footer
	log "FINISHED : $pipeline ------------------------"
###############################################################################
