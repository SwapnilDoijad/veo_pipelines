#!/bin/bash
###############################################################################
    pipeline=0041_genome_assembly_by_shovill
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -------------------------------------"
###############################################################################
## step-01: preparations

    fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    ls $fastq_path/ | sed 's/\.fastq\.gz//g' | sort | uniq | sed 's/_R1_001//g' | sed 's/_R2_001//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
