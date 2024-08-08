#!/bin/bash
###############################################################################
# 0642 jaeger
###############################################################################
## step-00: preparations
    if [ -f list.my_fasta.txt ]; then 
        list=list.my_fasta.txt
        elif [ -f list.bacterial_fasta.txt ] ; then 
        list=list.bacterial_fasta.txt 
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    (mkdir -p results/0642_jaeger/raw_files ) > /dev/null 2>&1
    my_fasta_path=$(grep fasta result_summary.read_me.txt | awk '{print $NF}')
###############################################################################
## step-01: run jaeger tool

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate jaeger_v1.31.0

    for fasta in $(cat $list ); do
        if [ ! -f results/0642_jaeger/raw_files/"$fasta"_jaeger.tsv ] ; then 
            echo "running $fasta"
            jaeger -i  $my_fasta_path/$fasta.fasta -o results/0642_jaeger/raw_files/
            else
            echo "$fasta already finished"
        fi
    done

###############################################################################
