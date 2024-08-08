#!/bin/bash
###############################################################################
## header
    # echo "Swapnil, update the script so that you can use three gpus (change codes to serially updated gpu013, gpu014, gpu015)"
    # echo "see, /home/xa73pav/scripts/database_maintainance/mgnify/assemblies_and_jaeger/results/0644_phage_detection_by_jaeger-gpu-parallel/tmp/sbatch"
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0644_phage_detection_by_jaeger-gpu-parallel --------------------------"
###############################################################################
## step-01: preparations

    pipeline=0644_phage_detection_by_jaeger-gpu-parallel
    wd=results/$pipeline

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    create_directories_structure_1 $wd


    grep -v '^#' tmp/parameters/$pipeline.txt \
    > tmp/parameters/$pipeline.csv

    mkdir -p $wd/tmp/fasta > /dev/null 2>&1
    while IFS= read -r my_file_path; do 
        suffix="${my_file_path##*.}"
        file_id="$(basename "$my_file_path" .$suffix)"
        sed "s/>/>"$file_id"_/g" $my_file_path > $wd/tmp/fasta/$file_id.fasta
    done < <(grep -v '^#' tmp/parameters/$pipeline.txt | grep -v paths )

    echo paths > $wd/tmp/$pipeline.csv
    ls $wd/tmp/fasta/*.fasta >> $wd/tmp/$pipeline.csv
    submit_jobs $wd $pipeline
###############################################################################
    echo "ENDED : 0644_phage_detection_by_jaeger-gpu-parallel ----------------------------"
###############################################################################
