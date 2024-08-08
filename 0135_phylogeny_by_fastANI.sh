#!/bin/bash
###############################################################################
## notes
    ## doesnt work if teh ANI is less than 80%
    ## therefore not recommended for diverse genomes
    ## not suitnale for metagenomes
    ## optoin: mash distance tree
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0135_phylogeny_by_fastANI -----------------------------------"
###############################################################################
## step-00: preparation
    pipeline=0135_phylogeny_by_fastANI
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
###############################################################################
## step-01: preparation for fastANI
    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0135_phylogeny_by_fastANI.sbatch
###############################################################################