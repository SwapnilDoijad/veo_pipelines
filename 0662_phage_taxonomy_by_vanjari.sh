#!/bin/bash
###############################################################################
## header
    pipeline=0662_phage_taxonomy_by_vanjari
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )

    ls $fasta_directory | sed 's/\.fasta$//' > list.$pipeline.txt
    # basename -a $fasta_directory/*.fasta | sed 's/\.fasta$//' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    cp /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch $wd/tmp/sbatch/
    sbatch $wd/tmp/sbatch/$pipeline.sbatch
###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################