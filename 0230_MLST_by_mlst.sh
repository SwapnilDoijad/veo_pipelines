#!/bin/bash
###############################################################################
## header
    pipeline=0230_MLST_by_mlst
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    log "STARTED SUBMISSION: $pipeline "
###############################################################################
    fasta_dir=$( grep my_fasta_dir  $parameters | awk '{print $2}' )
    ls $fasta_dir | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

	create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
    log "SUBMITTED: $pipeline "
###############################################################################
