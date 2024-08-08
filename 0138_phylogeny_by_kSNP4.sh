#!/bin/bash
###############################################################################
## header
    pipeline=0138_phylogeny_by_kSNP4
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : SBATCH SUBMISSION : $pipeline --------------------------------------"
###############################################################################
## 00 preparations 
    fasta_dir=$(grep "my_fasta_dir" $parameters | awk '{print $NF}')
    ls $fasta_path/ | sed 's/.fasta//g' > list.fasta.txt
    list=list.fasta.txt

    create_directories_structure_1 $wd

###############################################################################
## 01 run kSNP4

	sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0138_phylogeny_by_kSNP4.sbatch #> /dev/null 2>&1

###############################################################################
    echo "FINISHED : SBATCH SUBMISSION : $pipeline --------------------------------------"
###############################################################################