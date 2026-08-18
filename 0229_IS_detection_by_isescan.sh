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

    if [ $number_of_genomes -gt 1000 ]; then
        split_list $wd $list
        submit_jobs $wd $pipeline
    else
        cp ${suppl_scripts}/${pipeline}.array.sbatch \
        $wd/tmp/sbatch/${pipeline}.array.sbatch

        jobid=$(sbatch --parsable --array=1-${number_of_genomes}%20 $wd/tmp/sbatch/${pipeline}.array.sbatch)
    fi

###############################################################################
    conclude ${jobid}
    log "SUBMITTED: $pipeline"
###############################################################################
