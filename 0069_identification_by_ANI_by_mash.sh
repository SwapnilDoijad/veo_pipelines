#!/bin/bash
###############################################################################
## header
    pipeline=0069_identification_by_ANI_by_mash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline"
###############################################################################
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    type_strain_fasta_directory=$( grep my_type_strain_fasta_path $parameters | awk '{print $2}' )
    ls $fasta_directory | grep -v "fasta.fai" |  sed 's/.fasta//g' | sed 's/.fna//g' | sed 's/.fa//g' > list.$pipeline.txt
    ls $type_strain_fasta_directory | grep -v "fasta.fai" |  sed 's/.fasta//g' | sed 's/.fna//g' | sed 's/.fa//g' > list.$pipeline.type_strain.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd

    (mkdir -p $raw_files/msh/distance)> /dev/null 2>&1

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch

###############################################################################
    log "FINISHED: $pipeline"
###############################################################################


    