#!/bin/bash
###############################################################################
## header
    pipeline=0642_phage_detection_by_jaeger_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0642_phage_detection_by_jaeger_gpu --------------------------"
###############################################################################
## step-01: preparations

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
    split_list $wd $list
    # submit_jobs $wd $pipeline
    sbatch $suppl_scripts/$pipeline.sbatch

    echo -e "ids\tnumber_of_phages"$wd/phage_count.tsv > $wd/phage_count.tsv
###############################################################################
    echo "ENDED : 0642_phage_detection_by_jaeger_gpu ----------------------------"
###############################################################################
