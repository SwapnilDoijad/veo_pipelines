#!/bin/bash
###############################################################################
echo "started.... step-4 assembly --------------------------------------------"
###############################################################################
## step-01: file and directory preparation

	#tools
	spades=$(echo "python3.6 /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py" )
	fastq_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')

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

	(mkdir -p results/0040_assembly_for_nanopore_by_spades/raw_files ) > /dev/null 2>&1 
	(mkdir -p results/0040_assembly_for_nanopore_by_spades/all_fasta ) > /dev/null 2>&1 
###############################################################################
## step-02: run Spades assembler 
	for F1 in $(cat $list); do
		if [ ! -f results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.fasta ]; then
			echo "running assembly for... $F1"
			(mkdir results/0040_assembly_for_nanopore_by_spades/raw_files/$F1) > /dev/null 2>&1
			$spades --isolate \
			--nanopore $fastq_path/"$F1".fastq.gz \
			-m 3000 -o results/0040_assembly_for_nanopore_by_spades/raw_files/$F1
			#--cov-cutoff 5 --phred-offset 15 --isolate -m 3000 -o results/0040_assembly_for_nanopore_by_spades/raw_files/$F1
			echo "assembly for... $F1 finished"
			else
			echo "assembly for... $F1 already finished"
		fi
	done

exit 
###############################################################################
## step-03: post-assembly statistics and coverting fasta files
	for F1 in $(cat $list); do
		if [ ! -f  results/0040_assembly_for_nanopore_by_spades/all_fasta/$F1.fasta ]; then
			cp  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/contigs.fasta  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.fasta
			V1=$(grep -c ">"  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.fasta)
			grep -F ">"  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.fasta | sed -e 's/_/ /g' | sort -nrk 6 | awk '$6>=5.0 && $4>=500 {print $0}' | sed -s 's/ /_/g' | sed -e 's/>//g' >  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/tmp/$F1.10-500-filtered-contigs.csv
			perl /home/groups/VEO/tools/suppl_scripts/fastagrep.pl -f results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/tmp/$F1.10-500-filtered-contigs.csv results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.fasta > results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta
			V2=$(grep -c ">"  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta)
			V3=$(awk -F '_' '{ sum += $6; n++ } END { if (n > 0) print sum / n; }'  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/tmp/$F1.10-500-filtered-contigs.csv)
			echo $V1 $V2 $V3 >  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/tmp/$F1.5_filtering_contigs.statistics.tab
			cp  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta results/0040_assembly_for_nanopore_by_spades/all_fasta/$F1.fasta
			sed -i 's/>.*/NNNNNNNNNN/g' results/0040_assembly_for_nanopore_by_spades/all_fasta/$F1.fasta
			sed -i "\$aNNNNNNNNNN" results/0040_assembly_for_nanopore_by_spades/all_fasta/$F1.fasta
			sed -i "1i "'>'$F1"" results/0040_assembly_for_nanopore_by_spades/all_fasta/$F1.fasta
		fi
	done

###############################################################################
## Quality control by assembly-stat and quast
	(/home/groups/VEO/tools/assembly-stats-master/build/assembly-stats -t  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/contigs.fasta >  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.raw-assembly.stat.tab) > /dev/null 2>&1
	(/home/groups/VEO/tools/assembly-stats-master/build/assembly-stats -u  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta >>  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.filtered-assembly.stat.tab) > /dev/null 2>&1
	#(quast.py  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.fasta --output-dir  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/quast_raw_fasta) > /dev/null 2>&1
	#(quast.py  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta --output-dir  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/quast_filtered_fasta) > /dev/null 2>&1
	echo "finished... step-4 assembly for..." $F1

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

	(mkdir results/0040_assembly/00_icarus) > /dev/null 2>&1
	(mkdir results/0040_assembly/00_icarus/contigs_filtered_fasta) > /dev/null 2>&1

	for F1 in $(cat $list); do
	cp  results/0040_assembly_for_nanopore_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta results/0040_assembly/00_icarus/contigs_filtered_fasta/
	done
	(quast.py results/0040_assembly/00_icarus/contigs_filtered_fasta/*.fasta -R results/00_ref/ref.*.gbk -G results/00_ref/ref.*.gff --output-dir results/0040_assembly/00_icarus/) > /dev/null 2>&1
	fi
###############################################################################
echo "completed.. step-4 assembly -------------------------------------------" 
###############################################################################



