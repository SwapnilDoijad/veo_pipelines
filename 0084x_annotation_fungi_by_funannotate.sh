#!/bin/bash
###############################################################################
# b08 annotation 
###############################################################################
echo "started... 0084_annotation_fungi_by_funannotate -------------------------------------------"
###############################################################################
    if [ -f list.fungal_fasta.txt ]; then 
        list=list.fungal_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    (mkdir -p results/0084_annotation_fungi_by_funannotate/raw_files) > /dev/null 2>&1
    (mkdir -p results/0084_annotation_fungi_by_funannotate/tmp/slurm) > /dev/null 2>&1
    (mkdir -p results/0084_annotation_fungi_by_funannotate/tmp/sbatch) > /dev/null 2>&1
    (mkdir -p results/0084_annotation_fungi_by_funannotate/tmp/lists) > /dev/null 2>&1

    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep -w "^fasta" result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path 
    fi 
    
    ## sublist
    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 10 ))
    split -l "$lines_per_part" "$list" list.0084_annotation_fungi_by_funannotate_
    mv list.0084_annotation_fungi_by_funannotate_* results/0084_annotation_fungi_by_funannotate/tmp/lists/
##############################################################################
## step-01: sbatch
    for sublist in $( ls results/0084_annotation_fungi_by_funannotate/tmp/lists/ ) ; do
        echo "batch $sublist for prokka annotation: creating" 
        
        sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0084_annotation_fungi_by_funannotate.sbatch \
        | sed "s#XYZ#$fasta_file_path#g" \
        > results/0084_annotation_fungi_by_funannotate/tmp/sbatch/0084_annotation_fungi_by_funannotate.$sublist.sbatch

        sbatch results/0084_annotation_fungi_by_funannotate/tmp/sbatch/0084_annotation_fungi_by_funannotate.$sublist.sbatch

        echo "batch $sublist for funannotate annotation: submitted" 
    done

###############################################################################
echo "completed... 0084_annotation_fungi_by_funannotate -----------------------------------------"
###############################################################################