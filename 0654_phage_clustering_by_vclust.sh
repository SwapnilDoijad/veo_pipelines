#!/bin/bash
###############################################################################
## header
    pipeline=0654_phage_clustering_by_vclust
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    ls $fasta_directory | sed 's/.fasta//g' | sed 's/.fna//g' | sed 's/.fa//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd

    cp /home/groups/VEO/scripts_for_users/supplementary_scripts/0654_phage_clustering_by_vclust.sbatch $wd/tmp/sbatch/
	sbatch $wd/tmp/sbatch/0654_phage_clustering_by_vclust.sbatch
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################