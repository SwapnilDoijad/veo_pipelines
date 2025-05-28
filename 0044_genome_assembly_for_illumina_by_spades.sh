#!/bin/bash
###############################################################################
## header
	pipeline=0044_genome_assembly_for_illumina_by_spades
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : $pipeline started ------------------------------------"
###############################################################################
## step-01: file and directory preparation 

	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
	ls $fastq_path/ | sed 's/_R1_001\.filtered_paired\.fastq\.gz//g' | sed 's/_R2_001\.filtered_paired\.fastq\.gz//g' | sort | uniq > list.$pipeline.txt
	list=list.$pipeline.txt

	echo -e "IDs\tnumber_of_contigs" > $summary.tsv

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

	(mkdir -p results/0044_genome_assembly_for_illumina_by_spades/all_fasta ) > /dev/null 2>&1 

###############################################################################
## All-together quast
	# echo "Do you want to run quast for all fasta? answer yes or PRESS ENTER to skip" 
	# read F2
	# if [ "$F2" == "yes" ]; then
	# 	if [ ! -f results/00_ref/ref.*.fasta ] && [ ! -f results/00_ref/ref.*.gff ]; then
	# 	echo "ref.*.fasta or ref.*.gff is ABSENT, please add them in results/00_ref/ and then press enter"
	# 	read -p "Press enter to continue"
	# 	fi

	# (mkdir results/0044_genome_assembly_for_illumina_by_spades/00_icarus) > /dev/null 2>&1
	# (mkdir results/0044_genome_assembly_for_illumina_by_spades/00_icarus/contigs_filtered_fasta) > /dev/null 2>&1

	# for F1 in $(cat $list); do
	# cp  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta results/0044_genome_assembly_for_illumina_by_spades/00_icarus/contigs_filtered_fasta/
	# done
	# (quast.py results/0044_genome_assembly_for_illumina_by_spades/00_icarus/contigs_filtered_fasta/*.fasta -R results/00_ref/ref.*.gbk -G results/00_ref/ref.*.gff --output-dir results/0044_genome_assembly_for_illumina_by_spades/00_icarus/) > /dev/null 2>&1
	# fi
###############################################################################
echo "completed.. step-4 assembly -------------------------------------------" 
###############################################################################



