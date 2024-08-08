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

	(mkdir -p results/0047_genome_assembly_for_illumina_by_velvet/raw_files/ ) > /dev/null 2>&1 
	(mkdir -p results/0047_genome_assembly_for_illumina_by_velvet/all_fasta ) > /dev/null 2>&1 
############################################################################### 
## step-01b: check if raw-reads if filtered or not
	for F1 in $(cat $list); do
		if [ ! -f results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R1_001.filtered_paired.fastq.gz ] && [ ! -f results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R2_001.filtered_paired.fastq.gz  ] ; then
			echo "filtered reads not present"
			## then, run filter read step
			if [ -f $fastq_file_path/"$F1"_R1_001.fastq.gz ] && [ -f $fastq_file_path/"$F1"_R2_001.fastq.gz  ] ; then
				echo "filtering reads"
				/home/groups/VEO/scripts_for_users/0021_filter_rawreads_by_trimmomatic.sh
				else
				echo "fastqs are absent"
			fi
			else
			echo "filtered reads are present for $F1"
		fi
	done 
###############################################################################
## step-02: run velvet assembler 
	for F1 in $(cat $list); do
	VelvetOptimiser.pl -s 21 -e 31 -x 4 -f '-shortPaired -fastq -separate $READS1 $READS2' -t 2 -o "$OUTPUT_DIR"
	done 

exit 
	for F1 in $(cat $list); do
		if [ ! -f results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.fasta ]; then
			echo "running assembly for... $F1"
			(mkdir results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1) > /dev/null 2>&1
			python3.6 /home/groups/VEO/tools/v3.15.5/bin/spades.py \
			-1 results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R1_001.filtered_paired.fastq.gz \
			-2 results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R2_001.filtered_paired.fastq.gz \
			--cov-cutoff 5 -t 80 -k 127 --phred-offset 33 --isolate -m 980 -o results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/K21) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/K33) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/K55) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/K77) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/K99) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/K127) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/corrected) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/configs) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/misc) > /dev/null 2>&1
			(rm -r results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/tmp) > /dev/null 2>&1
			(mkdir results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/tmp) > /dev/null 2>&1
			echo "assembly for... $F1 finished"
			else
			echo "assembly for... $F1 already finished"
		fi
	done
exit 

###############################################################################
## step-03: post-assembly statistics and coverting fasta files
	for F1 in $(cat $list); do
		if [ ! -f  results/0047_genome_assembly_for_illumina_by_velvet/all_fasta/$F1.fasta ]; then
			cp  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/contigs.fasta  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.fasta
			V1=$(grep -c ">"  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.fasta)
			grep -F ">"  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.fasta | sed -e 's/_/ /g' | sort -nrk 6 | awk '$6>=5.0 && $4>=500 {print $0}' | sed -s 's/ /_/g' | sed -e 's/>//g' >  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/tmp/$F1.10-500-filtered-contigs.csv
			perl /home/groups/VEO/tools/suppl_scripts/fastagrep.pl -f results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/tmp/$F1.10-500-filtered-contigs.csv results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.fasta > results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.contigs-filtered.fasta
			V2=$(grep -c ">"  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.contigs-filtered.fasta)
			V3=$(awk -F '_' '{ sum += $6; n++ } END { if (n > 0) print sum / n; }'  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/tmp/$F1.10-500-filtered-contigs.csv)
			echo $V1 $V2 $V3 >  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/tmp/$F1.5_filtering_contigs.statistics.tab
			cp  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.contigs-filtered.fasta results/0047_genome_assembly_for_illumina_by_velvet/all_fasta/$F1.fasta
			sed -i 's/>.*/NNNNNNNNNN/g' results/0047_genome_assembly_for_illumina_by_velvet/all_fasta/$F1.fasta
			sed -i "\$aNNNNNNNNNN" results/0047_genome_assembly_for_illumina_by_velvet/all_fasta/$F1.fasta
			sed -i "1i "'>'$F1"" results/0047_genome_assembly_for_illumina_by_velvet/all_fasta/$F1.fasta
		fi
	done

###############################################################################
## Quality control by assembly-stat and quast
	(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats -t  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/contigs.fasta >  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.raw-assembly.stat.tab) > /dev/null 2>&1
	(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats -u  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.contigs-filtered.fasta >>  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.filtered-assembly.stat.tab) > /dev/null 2>&1
	#(quast.py  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.fasta --output-dir  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/quast_raw_fasta) > /dev/null 2>&1
	#(quast.py  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.contigs-filtered.fasta --output-dir  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/quast_filtered_fasta) > /dev/null 2>&1
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

	(mkdir results/0047_genome_assembly_for_illumina_by_velvet/00_icarus) > /dev/null 2>&1
	(mkdir results/0047_genome_assembly_for_illumina_by_velvet/00_icarus/contigs_filtered_fasta) > /dev/null 2>&1

	for F1 in $(cat $list); do
	cp  results/0047_genome_assembly_for_illumina_by_velvet/raw_files/$F1/$F1.contigs-filtered.fasta results/0047_genome_assembly_for_illumina_by_velvet/00_icarus/contigs_filtered_fasta/
	done
	(quast.py results/0047_genome_assembly_for_illumina_by_velvet/00_icarus/contigs_filtered_fasta/*.fasta -R results/00_ref/ref.*.gbk -G results/00_ref/ref.*.gff --output-dir results/0047_genome_assembly_for_illumina_by_velvet/00_icarus/) > /dev/null 2>&1
	fi
###############################################################################
echo "completed.. step-4 assembly -------------------------------------------" 
###############################################################################



