#!/bin/bash
###############################################################################
echo "started.... step-4 assembly --------------------------------------------"
############################################################################### 
## step-01: file and directory preparation 
    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		ls list.*.txt | sed 's/ /\n/g'
		read l
		list=$(echo "list.$l.txt")
	fi

	if [ -f result_summary.read_me.txt ]; then
        fastq_file_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fastq_file_path"
        read fastq_file_path
    fi

	(mkdir -p results/0044_genome_assembly_for_illumina_by_spades/raw_files ) > /dev/null 2>&1 
	(mkdir -p results/0044_genome_assembly_for_illumina_by_spades/all_fasta ) > /dev/null 2>&1 
	(mkdir -p results/0044_genome_assembly_for_illumina_by_spades/tmp/lists ) > /dev/null 2>&1 
	(mkdir -p results/0044_genome_assembly_for_illumina_by_spades/tmp/slurm ) > /dev/null 2>&1 
	(mkdir -p results/0044_genome_assembly_for_illumina_by_spades/tmp/sbatch ) > /dev/null 2>&1 

    ## sublist
    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 10 ))
    split -l "$lines_per_part" "$list" list.0044_genome_assembly_for_illumina_by_spades_
    mv list.0044_genome_assembly_for_illumina_by_spades_* results/0044_genome_assembly_for_illumina_by_spades/tmp/lists/

###############################################################################
## step-01:  sbatch
    for sublist in $( ls results/0044_genome_assembly_for_illumina_by_spades/tmp/lists/ ) ; do
        echo "batch $sublist for shovill : creating" 
        
        sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts//0044_genome_assembly_for_illumina_by_spades.sbatch \
        | sed "s#XYZ#$fastq_file_path#g" \
        > results/0044_genome_assembly_for_illumina_by_spades/tmp/sbatch//0044_genome_assembly_for_illumina_by_spades.$sublist.sbatch

        sbatch results/0044_genome_assembly_for_illumina_by_spades/tmp/sbatch/0044_genome_assembly_for_illumina_by_spades.$sublist.sbatch

        echo "batch $sublist for shovill : submitted" 
    done

###############################################################################



exit
###############################################################################
## All-together quast
	echo "Do you want to run quast for all fasta? answer yes or PRESS ENTER to skip" 
	read F2
	if [ "$F2" == "yes" ]; then
		if [ ! -f results/00_ref/ref.*.fasta ] && [ ! -f results/00_ref/ref.*.gff ]; then
		echo "ref.*.fasta or ref.*.gff is ABSENT, please add them in results/00_ref/ and then press enter"
		read -p "Press enter to continue"
		fi

	(mkdir results/0044_genome_assembly_for_illumina_by_spades/00_icarus) > /dev/null 2>&1
	(mkdir results/0044_genome_assembly_for_illumina_by_spades/00_icarus/contigs_filtered_fasta) > /dev/null 2>&1

	for F1 in $(cat $list); do
	cp  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta results/0044_genome_assembly_for_illumina_by_spades/00_icarus/contigs_filtered_fasta/
	done
	(quast.py results/0044_genome_assembly_for_illumina_by_spades/00_icarus/contigs_filtered_fasta/*.fasta -R results/00_ref/ref.*.gbk -G results/00_ref/ref.*.gff --output-dir results/0044_genome_assembly_for_illumina_by_spades/00_icarus/) > /dev/null 2>&1
	fi
###############################################################################
echo "completed.. step-4 assembly -------------------------------------------" 
###############################################################################



