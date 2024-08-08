#!/bin/bash
###############################################################################
## step-1: identify type of data, path, and amount of data present
###############################################################################
    fasta_file_path=$( find -type f -name "*.fasta" | head -1 | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' |  sed 's/^..//' | sed 's/.$//' )
    fastq_file_path=$( find -type f -name "*.fastq.gz" | head -1 | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' |  sed 's/^..//' | sed 's/.$//' )
    echo "--------------------------------------------------------------------------------"
    if [ ! -z $fasta_file_path ]; then
        fasta_file_count=$(ls $fasta_file_path | wc -l )
        test_fasta_file=$(ls $fasta_file_path | head -1 )
        fasta_file_length=$(cat $fasta_file_path/$test_fasta_file | wc -c )
        if [[ $fasta_file_length -gt 500000 ]]; then
            type_of_files=bacterial_fasta
            else
            type_of_files=prophage_fasta
        fi
        echo "$fasta_file_count $type_of_files files found at $fasta_file_path"
        echo "Note that, genomes <500,000 bp are consider are of phage!"
        echo "$fasta_file_count $type_of_files files found at $fasta_file_path" > result_summary.read_me.txt
    fi

    if [ ! -z $fastq_file_path ]; then
        fastq_file_count=$(ls $fastq_file_path | wc -l )
        echo "$fastq_file_count fastq.gz (raw_read) files found at $fastq_file_path"
        echo "$fastq_file_count fastq.gz (raw_read) files found at $fastq_file_path" >> result_summary.read_me.txt
    fi

    echo "--------------------------------------------------------------------------------"
###############################################################################
## step-2: create a list of files

    if [ "$type_of_files" == bacterial_fasta ] ; then
        #echo "$fasta fasta found, writing list.my_bacterial_fasta.txt file"
        ( ls $fasta_file_path | awk -F'/' '{print $NF}'| sed 's/\.fasta//g' | sort -u > list.bacterial_fasta.txt ) > /dev/null 2>&1
        ( mkdir -p results/0040_assembly/all_fasta ) > /dev/null 2>&1
        echo "copying $type_of_files"
        ( cp $fasta_file_path/*.fasta results/0040_assembly/all_fasta) > /dev/null 2>&1
    fi

    if [ "$type_of_files" == prophage_fasta ] ; then
        #echo "$fasta fasta found, writing list.my_prophage_fasta.txt file"
        ( ls $fasta_file_path | awk -F'/' '{print $NF}'| sed 's/\.fasta//g' | sort -u > list.prophage_fasta.txt ) > /dev/null 2>&1
        ( mkdir -p results/0040_assembly/all_fasta_prophage ) > /dev/null 2>&1
        echo "copying $type_of_files"
        ( cp $fasta_file_path/*.fasta results/0040_assembly/all_fasta_prophage) > /dev/null 2>&1
    fi

    if [ ! -z $fastq_file_path ] ; then
        #echo "$fasta fasta found, writing list.my_fastq.txt file"
        ( ls $fastq_file_path | awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' | awk -F'_' '{print $1}' | sort -u > list.fastq.txt ) > /dev/null 2>&1
        ( mkdir -p data/illumina/raw_reads ) > /dev/null 2>&1
        echo "copying fastq files"
        ( cp $fastq_file_path/*.fastq.gz data/illumina/raw_reads/) > /dev/null 2>&1
    fi

    if [ -z "$type_of_files" ] && [ -z "$fastq_file_path" ] ; then 
        echo "--------------------------------------------------------------------------------"
        echo "NO FILES FOUND!"
        echo "  In current directory (or sub-directory) .fasta files could not not be located "
        echo "  Please create a directory and place your .fasta files, and re-run"
        echo "  currenty script is not configured for .fna file, please rename to .fasta "
        echo "  "
        echo "  for e.g."
        echo "  "
        echo "      for fasta files"
        echo "      my_fasta/1.fasta"
        echo "      my_fasta/2.fasta"
        echo "      my_fasta/3.fasta"
        echo "      my_fasta/...."
        #echo "      "
        #echo "      for fastq.gz files"
        #echo "      my_fastq/a.fastq.gz"
        #echo "      my_fastq/b.fastq.gz"
        #echo "      my_fastq/c.fastq.gz"
        #echo "      my_fastq/..."
        echo "--------------------------------------------------------------------------------"
    fi 
###############################################################################