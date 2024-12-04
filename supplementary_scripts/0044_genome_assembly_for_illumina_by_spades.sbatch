#!/bin/bash
#SBATCH --job-name 0044_genome_assembly_for_illumina_by_spades
#SBATCH --partition=standard
#SBATCH --output results/0044_genome_assembly_for_illumina_by_spades/tmp/slurm/%j.out
#SBATCH --error results/0044_genome_assembly_for_illumina_by_spades/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
#-- Command section ------------------------

    sublist=results/0044_genome_assembly_for_illumina_by_spades/tmp/lists/ABC
    fastq_file_path=XYZ

############################################################################### 
## step-01b: check if raw-reads if filtered or not
	for F1 in $(cat $sublist); do
		if [ ! -f results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R1_001.filtered_paired.fastq.gz ] && [ ! -f results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R2_001.filtered_paired.fastq.gz  ] ; then
              results/0021_filter_reads_by_trimmomatic/31107401992-Isolate-1-CPHRNIMS-01-NCGM-1781/31107401992-Isolate-1-CPHRNIMS-01-NCGM-1781_R1_001.filtered_paired.fastq.gz
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
## step-02: run Spades assembler 
	for F1 in $(cat $sublist); do
		if [ ! -f results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.fasta ]; then
			echo "running assembly for... $F1"
			(mkdir results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1) > /dev/null 2>&1
			python3.6 /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
			-1 results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R1_001.filtered_paired.fastq.gz \
			-2 results/0021_filter_reads_by_trimmomatic/$F1/"$F1"_R2_001.filtered_paired.fastq.gz \
			--cov-cutoff 5 -t 80 -k 127 -m 200 --phred-offset 33 --isolate -o results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/K21) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/K33) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/K55) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/K77) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/K99) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/K127) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/corrected) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/configs) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/misc) > /dev/null 2>&1
			(rm -r results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/tmp) > /dev/null 2>&1
			(mkdir results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/tmp) > /dev/null 2>&1
			echo "assembly for... $F1 finished"
			else
			echo "assembly for... $F1 already finished" 
		fi
	done 

###############################################################################
## step-03: post-assembly statistics and coverting fasta files
	for F1 in $(cat $sublist); do
		if [ ! -f  results/0044_genome_assembly_for_illumina_by_spades/all_fasta/$F1.fasta ]; then
			echo "running post-assembly statistics and coverting fasta files for... $F1"
			cp  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/contigs.fasta  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.fasta
			V1=$(grep -c ">"  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.fasta)
			grep -F ">"  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.fasta | sed -e 's/_/ /g' | sort -nrk 6 | awk '$6>=5.0 && $4>=1000 {print $0}' | sed -s 's/ /_/g' | sed -e 's/>//g' >  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/tmp/$F1.10-1000-filtered-contigs.csv
			perl /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl -f results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/tmp/$F1.10-1000-filtered-contigs.csv results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.fasta > results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta
			V2=$(grep -c ">"  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta)
			V3=$(awk -F '_' '{ sum += $6; n++ } END { if (n > 0) print sum / n; }'  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/tmp/$F1.10-1000-filtered-contigs.csv)
			echo $V1 $V2 $V3 >  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/tmp/$F1.5_filtering_contigs.statistics.tab
			cp  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta results/0044_genome_assembly_for_illumina_by_spades/all_fasta/$F1.fasta
			sed -i 's/>.*/NNNNNNNNNN/g' results/0044_genome_assembly_for_illumina_by_spades/all_fasta/$F1.fasta
			sed -i "\$aNNNNNNNNNN" results/0044_genome_assembly_for_illumina_by_spades/all_fasta/$F1.fasta
			sed -i "1i "'>'$F1"" results/0044_genome_assembly_for_illumina_by_spades/all_fasta/$F1.fasta
			else
			echo "post-assembly statistics and coverting fasta files for... $F1 already finished"
			fi
	done 

###############################################################################
## Quality control by assembly-stat and quast
	for F1 in $(cat $sublist); do

		if [ ! -f results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.raw-assembly.stat.tab ]; then 
			echo "running assembly-stat for $F1"
			(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
			-t  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/contigs.fasta \
			>  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.raw-assembly.stat.tab) > /dev/null 2>&1

			(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
			-u  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta \
			>>  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.filtered-assembly.stat.tab) > /dev/null 2>&1

			else
			echo "assembly-stat for $F1 already finished"
		fi 

		if [ -f results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/quast_raw_fasta ]; then
			echo "running quast for $F1"
			( python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
			results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.fasta \
			--output-dir  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/quast_raw_fasta ) > /dev/null 2>&1

			( python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
			results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/$F1.contigs-filtered.fasta \
			--output-dir  results/0044_genome_assembly_for_illumina_by_spades/raw_files/$F1/quast_filtered_fasta ) > /dev/null 2>&1
			else
			echo "quast for $F1 already finished"
		fi
		
		echo "finished... step-4 assembly for..." $F1
	done 
###############################################################################