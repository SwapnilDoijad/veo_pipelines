#!/bin/bash
###############################################################################
## header
    pipeline=0137_phylogeny_ANI_by_mash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline"
###############################################################################
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    ls $fasta_directory | sed 's/.fasta//g' | sed 's/.fna//g' | sed 's/.fa//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd

    (mkdir -p $raw_files/tmp)> /dev/null 2>&1
    (mkdir -p $raw_files/msh/distance)> /dev/null 2>&1
    (mkdir -p $raw_files/msh/distance/tmp)> /dev/null 2>&1

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0137_phylogeny_ANI_by_mash.sbatch


###############################################################################
    log "FINISHED: $pipeline"
###############################################################################
