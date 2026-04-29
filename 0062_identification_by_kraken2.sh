#!/bin/bash
###############################################################################
    pipeline=0062_identification_by_kraken2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    log "STARTED: $pipeline"

    data_path=$(grep "my_data_dir" $parameters | awk '{print $2}')
    input_file_type=$( grep "my_input_file_type" $parameters | awk -F'\t' '{print $2}')

    if [  "$input_file_type" == "f" ] ; then 
        ls $data_path/ | sed 's/\.fasta//g' > list.$pipeline.txt
    elif [ "$input_file_type" == "r" ] ; then
        ls $data_path/ | sed 's/_R1.fastq.gz//g' | sed 's/_R2.fastq.gz//g' | sed 's/.fastq.gz//g' | sort -u > list.$pipeline.txt
    fi

    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

    echo -e "id\tPercFrag\tNumbFrag\tNumbFragAssig\trank\tNCBIid\tSpecies" > $wd/report.csv
###############################################################################
    log "ENDED: $pipeline"
###############################################################################

