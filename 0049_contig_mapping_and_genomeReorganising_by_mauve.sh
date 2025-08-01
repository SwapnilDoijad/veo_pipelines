#!/bin/bash
###############################################################################
    pipeline=0049_contig_mapping_and_genomeReorganising_by_mauve
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline -----------------------------------------------------"
###############################################################################
    grep -v "#" $parameters | sed '/^$/d' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd list.$pipeline.txt
    submit_jobs $wd $pipeline
    
    mkdir $wd/all_fasta

###############################################################################
    log "ENDED : $pipeline ----------------------"
###############################################################################