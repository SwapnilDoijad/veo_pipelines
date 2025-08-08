#!/bin/bash
###############################################################################
## header
    pipeline=0656_phage_taxonomy_by_sourmash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    faa_path=$( grep my_faa_path $parameters | awk '{print $2}' )
	ls $faa_path/ | sed 's/\.faa//g ' > list.$pipeline.txt

    create_directories_structure_1 $wd

    cp /home/groups/VEO/scripts_for_users/supplementary_scripts/0651_phage_clustering_by_vcontact.sbatch \
    $wd/tmp/slurm/0651_phage_clustering_by_vcontact.sbatch
    
	sbatch $wd/tmp/slurm/0651_phage_clustering_by_vcontact.sbatch
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################