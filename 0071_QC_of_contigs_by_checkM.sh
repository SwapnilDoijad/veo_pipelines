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

    echo -e "Bin_Id\tMarker_lineage\tgenomes\tmarkers\tmarker_sets\t0\t1\t2\t3\t4\t5+\tCompleteness\tContamination\tStrain_heterogeneity" \
    > $wd/summary.tsv

###############################################################################
    echo "ENDED : 0071_QC_of_contigs_by_checkM -------------------------------------------------------"
###############################################################################