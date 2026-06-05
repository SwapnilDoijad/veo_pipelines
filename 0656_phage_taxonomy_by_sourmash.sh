#!/bin/bash
###############################################################################
## header
    pipeline=0656_phage_taxonomy_by_sourmash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	ls $fasta_directory/ | sed 's/\.fasta//g ' > list.$pipeline.txt

    create_directories_structure_1 $wd

    cp /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch \
    $wd/tmp/sbatch/$pipeline.sbatch

	# sbatch $wd/tmp/sbatch/$pipeline.sbatch
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################