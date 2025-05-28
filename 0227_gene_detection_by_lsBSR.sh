#!/bin/bash
###############################################################################
## header
    pipeline=0227_gene_detection_by_lsBSR
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED SUBMISSION: $pipeline "
###############################################################################
## step-01: file and directory preparation
    fasta_dir=$( grep my_fasta_dir  $parameters | awk '{print $2}' )
    ls $fasta_dir | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    
    cp /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch \
    $wd/tmp/sbatch/$pipeline.sbatch

    sbatch $wd/tmp/sbatch/$pipeline.sbatch
###############################################################################
## footer
    log "ENDED: $pipeline "
###############################################################################
