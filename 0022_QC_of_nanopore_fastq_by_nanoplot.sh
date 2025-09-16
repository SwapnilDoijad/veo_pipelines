#!/bin/bash
###############################################################################
## header
    pipeline=0022_QC_of_nanopore_fastq_by_nanoplot
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0022_QC_of_nanopore_fastq_by_nanoplot ---------------------------------"
###############################################################################
## step-01: file and directory preparation


    fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    ls $fastq_path/ | sed 's/\.fastq\.gz//g' | sed 's/_R1//g' | sed 's/_R2//g' | sort | uniq  > list.$pipeline.txt
    list=list.$pipeline.txt
    # fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    # ls $fastq_path/ | sed 's/\.fastq//g' | sed 's/_R1//g' | sed 's/_R2//g' | sort | uniq  > list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################