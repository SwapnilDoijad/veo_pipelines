#!/bin/bash
###############################################################################
# b08 annotation 
###############################################################################
echo "started... step-0081 annotation -------------------------------------------"
###############################################################################
## step-01: preparation
    pipeline=0081_annotation_bacteria_by_prokka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    if [ -f list.bacterial_fasta.txt ]; then 
        list=list.bacterial_fasta.txt
        elif [ -f list.prophage_fasta.txt ]; then 
        list=list.prophage_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi
    # list=list.top5_close_relatives.txt
    # fasta_file_path=data/top5_close_relatives

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
    
    # if [ -f result_summary.read_me.txt ]; then
    #     fasta_file_path=$(grep -w "^fasta" result_summary.read_me.txt | awk '{print $NF}')
    #     else
    #     echo "provide fasta_file_path"
    #     read fasta_file_path
    # fi 
    exit 
##############################################################################
## step-01: annotation sbatch
    for sublist in $( ls results/$pipeline/tmp/lists/ ) ; do
        echo "batch $sublist for prokka annotation: creating" 
        
        sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0081_annotation_bacteria_by_prokka.sbatch \
        | sed "s#XYZ#$fasta_file_path#g" \
        > results/$pipeline/tmp/sbatch/0081_annotation_bacteria_by_prokka.$sublist.sbatch

        sbatch results/$pipeline/tmp/sbatch/0081_annotation_bacteria_by_prokka.$sublist.sbatch

        echo "batch $sublist for prokka annotation: submitted" 
    done

###############################################################################
echo "completed... step-08 annotation -----------------------------------------"
###############################################################################
