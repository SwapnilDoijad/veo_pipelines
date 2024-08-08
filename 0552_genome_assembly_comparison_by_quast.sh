#!/bin/bash
###############################################################################
## header 
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: 0552_genome_assembly_comparison_by_quast --------------------"
###############################################################################
## step-01: preparation
    pipeline=0552_genome_assembly_comparison_by_quast
    wd=results/$pipeline

    mkdir -p $wd

    grep -v "#" tmp/parameters/$pipeline.txt | grep -v '^$' > $wd/tmp/parameters.txt

###############################################################################
## step-00: run QUAST

    if [ ! -d mkdir -p $wd/all_fasta ] ; then 
        mkdir -p $wd/all_fasta
        log "COPYING : fasta files to all_fasta"
        while IFS=$'\t' read -r identifier fasta_path; do
            for file in $(ls $fasta_path); do 
                cp $fasta_path/$file $wd/all_fasta/"$identifier"_"$file"
            done 
        done < $wd/tmp/parameters.txt
    fi 

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch  > /dev/null 2>&1

###############################################################################
log "ENDED : 0552_genome_assembly_comparison_by_quast ----------------------"
###############################################################################
