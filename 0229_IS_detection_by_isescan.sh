#!/bin/bash
###############################################################################
## header
    pipeline=0229_IS_detection_by_isescan
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    log "STARTED SUBMISSION: $pipeline "
###############################################################################
    fasta_dir=$( grep my_fasta_dir  $parameters | awk '{print $2}' )
    ls $fasta_dir | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt
    number_of_genomes=$(wc -l < $list)

	create_directories_structure_1 $wd
    # split_list $wd $list
    # submit_jobs $wd $pipeline
    cp ${suppl_scripts}/0229_IS_detection_by_isescan.sbatch \
    $wd/tmp/sbatch/0229_IS_detection_by_isescan.sbatch\

    jobid=$(sbatch --parsable --array=1-${number_of_genomes}%20 $wd/tmp/sbatch/0229_IS_detection_by_isescan.sbatch)

    sbatch \
    --dependency=afterok:$jobid \
    --wrap='echo "everything is done"'
###############################################################################
    log "SUBMITTED: $pipeline"
###############################################################################
