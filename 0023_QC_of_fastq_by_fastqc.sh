#!/bin/bash
###############################################################################
## header
    pipeline=0023_QC_of_fastq_by_fastqc
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline -----------------------------------------------"
###############################################################################

    fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    ls $fastq_path/ | sed 's/\.fastq\.gz//g' > list.$pipeline.txt
    list=list.$pipeline.txt
	
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
    log "FINISHED : $pipeline -----------------------------------------------"
###############################################################################