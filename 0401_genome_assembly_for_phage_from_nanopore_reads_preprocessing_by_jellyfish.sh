#!/bin/bash
###############################################################################
## header
    pipeline=0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

	fastq_path=$( grep my_fastq $parameters | awk '{print $2}' )
	minimum_length=$( grep my_minimum_length $parameters | awk '{print $2}' )
	maximum_length=$( grep my_maximum_length $parameters | awk '{print $2}' )
	phred=$(grep my_phred $parameters | awk '{print $2}')
	final_read_length=$(grep my_final_read_length $parameters | awk '{print $2}')
	subsample=$(grep my_subsample $parameters | awk '{print $2}')
	subsample_final=$(grep my_final_subsample $parameters | awk '{print $2}')
    
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline ## supplementary_scripts/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish.sbatch
    echo "id my_fastq_filtered_Q_reads my_fastq_filtered_Q_subsampled$subsample my_fastq_filtered_Q_subsampled"$subsample"_fasta my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length" my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"_subsampled"$subsample_final"reads" " | tr ' ' '\t' > $raw_files/summary.$final_read_length.tsv

###############################################################################
## footer
    log "FINISHED : $pipeline ---------------------------------"
###############################################################################