#!/bin/bash
###############################################################################
## header
    pipeline=0132_phylogeny_for_phage_by_shared_genome_content
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline"
###############################################################################
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    ls $fasta_directory | sed 's/.fasta//g' | sed 's/.fna//g' | sed 's/.fa//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    mkdir $raw_files/plots

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0132_phylogeny_for_phage_by_shared_genome_content.sbatch
###############################################################################
    log "FINISHED: $pipeline"
###############################################################################
