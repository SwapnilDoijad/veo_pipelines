#!/bin/bash
###############################################################################
## header 
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: 0043_genome_assembly_by_unicycler -------------------------------------"
###############################################################################
## step-01: preparation

	wd=results/0043_genome_assembly_by_unicycler
    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		read l
		list=$(echo "list.$l.txt")
	fi

	if [ -f result_summary.read_me.txt ]; then
        fastq_file_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fastq_file_path"
        read fastq_file_path
    fi

	#echo "do you want to analyze the NCBI data"$ncbi"? type ncbi for yes" 
	#read ncbi_tmp
	#	if [ $ncbi_tmp = "ncbi" ] ; then
	#		ncbi=$(echo "/$ncbi_tmp")
	#		else
	#		ncbi=$(echo "")
	#	fi

	(mkdir -p $wd/tmp) > /dev/null 2>&1
	(mkdir -p $wd/all_fasta) > /dev/null 2>&1
	(mkdir -p $wd/all_fasta_joined) > /dev/null 2>&1
###############################################################################
