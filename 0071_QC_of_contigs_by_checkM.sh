#!/bin/bash
###############################################################################
## header
    pipeline=0071_QC_of_contigs_by_checkM
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0071_QC_of_contigs_by_checkM -----------------------------------------------------"
###############################################################################
## step-01: preparations

    fasta_file_dir=$(grep "my_fasta_path" $parameters | awk '{print $2}')
    ls $fasta_file_dir | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
    echo "ENDED : 0071_QC_of_contigs_by_checkM -------------------------------------------------------"
###############################################################################