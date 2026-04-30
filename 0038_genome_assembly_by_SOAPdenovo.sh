#!/bin/bash
###############################################################################
    pipeline=0038_genome_assembly_by_SOAPdenovo
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -------------------------------------"
###############################################################################
## step-01: preparations

    fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    ls $fastq_path/ | awk -F'_' '{print $1}' | sort | uniq  > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    rm example.$pipeline.parameters

    mkdir $wd/tmp/parameters
    ls $fastq_path/*.gz > $wd/tmp/list.$pipeline.fastq.txt
    for i in $(cat list.$pipeline.txt); do
        > $wd/tmp/parameters/$i.parameters
        R1_path=$(grep $i $wd/tmp/list.$pipeline.fastq.txt | grep _R1)
        R2_path=$(grep $i $wd/tmp/list.$pipeline.fastq.txt | grep _R2)

        sed 's|R1_path|'$R1_path'|g;s|R2_path|'$R2_path'|g' $suppl_scripts/parameter_files/example.$pipeline.parameters \
        > $wd/tmp/parameters/$i.parameters

    done 

    submit_jobs $wd $pipeline
###############################################################################
