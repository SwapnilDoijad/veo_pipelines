#!/bin/bash
###############################################################################
## header
    pipeline=0777_amplicon_sequence_analysis_for_nanopore_by_nameco
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    fastq_directory=$( grep my_fastq_dir $parameters | awk '{print $2}' )
    basename -a $fastq_directory/*.fastq | sed 's/\.fastq$//' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    # split_list $wd $list
    # submit_jobs $wd $pipeline

	cp ${suppl_scripts}/$pipeline.sbatch \
	$wd/tmp/sbatch/

	sbatch $wd/tmp/sbatch/$pipeline.sbatch
	
###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################