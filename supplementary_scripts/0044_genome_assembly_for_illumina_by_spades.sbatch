#!/bin/bash
#SBATCH --job-name=0044_genome_assembly_for_illumina_by_spades
#SBATCH --partition=short,standard,long,interactive,gpu,gpu-veo
#SBATCH --output=results/0044_genome_assembly_for_illumina_by_spades/tmp/slurm/%j.out
#SBATCH --error=results/0044_genome_assembly_for_illumina_by_spades/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
############################################################################### 

	pipeline=0044_genome_assembly_for_illumina_by_spades
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	sublist=$wd/tmp/lists/ABC
	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )

	log "STARTED : $pipeline started ------------------------------------"

###############################################################################
## step-02: run Spades assembler 
	for F1 in $(cat $sublist); do
		if [ ! -f $raw_files/$F1/$F1.fasta ]; then
			log "running assembly for... $F1"
			(mkdir $raw_files/$F1) > /dev/null 2>&1
			python3.6 /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
			-1 $fastq_path/"$F1"_R1_001.filtered_paired.fastq.gz \
			-2 $fastq_path/"$F1"_R2_001.filtered_paired.fastq.gz \
			--cov-cutoff 5 -t 80 -k 127 -m 200 --phred-offset 33 --isolate -o $raw_files/$F1 \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$F1.spades.tsv 

			(rm -r $raw_files/$F1/K21) > /dev/null 2>&1
			(rm -r $raw_files/$F1/K33) > /dev/null 2>&1
			(rm -r $raw_files/$F1/K55) > /dev/null 2>&1
			(rm -r $raw_files/$F1/K77) > /dev/null 2>&1
			(rm -r $raw_files/$F1/K99) > /dev/null 2>&1
			(rm -r $raw_files/$F1/K127) > /dev/null 2>&1
			(rm -r $raw_files/$F1/corrected) > /dev/null 2>&1
			(rm -r $raw_files/$F1/configs) > /dev/null 2>&1
			(rm -r $raw_files/$F1/misc) > /dev/null 2>&1
			(rm -r $raw_files/$F1/tmp) > /dev/null 2>&1
			(mkdir $raw_files/$F1/tmp) > /dev/null 2>&1
			log "assembly for... $F1 finished"
			else
			log "assembly for... $F1 already finished" 
		fi
	done 

###############################################################################
## step-03: post-assembly statistics and converting fasta files
	for F1 in $(cat $sublist); do
		if [ ! -f $raw_files/all_fasta/$F1.fasta ]; then
			log "running post-assembly statistics and coverting fasta files for... $F1"
			cp  $raw_files/$F1/contigs.fasta  $raw_files/$F1/$F1.fasta
			number_of_raw_contigs=$(grep -c ">"  $raw_files/$F1/$F1.fasta)

			grep -F ">"  $raw_files/$F1/$F1.fasta | sed -e 's/_/ /g' | sort -nrk 6 | awk '$6>=5.0 && $4>=500 {print $0}' \
			| sed -s 's/ /_/g' | sed -e 's/>//g' \
			>  $raw_files/$F1/tmp/$F1.5-500-filtered-contigs.csv

			perl /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl \
			-f $raw_files/$F1/tmp/$F1.5-500-filtered-contigs.csv \
			$raw_files/$F1/$F1.fasta > $raw_files/$F1/$F1.contigs-filtered.fasta

			number_of_filtered_contigs=$(grep -c ">"  $raw_files/$F1/$F1.contigs-filtered.fasta)

			coverage=$(awk -F '_' '{ sum += $6; n++ } END { if (n > 0) print sum / n; }'  $raw_files/$F1/tmp/$F1.5-500-filtered-contigs.csv)

			echo number_of_raw_contigs number_of_filtered_contigs coverage | tr ' ' '\t' > $raw_files/$F1/tmp/$F1.05-500_filtering_contigs.statistics.tab
			echo $number_of_raw_contigs $number_of_filtered_contigs $coverage | tr ' ' '\t' >> $raw_files/$F1/tmp/$F1.05-500_filtering_contigs.statistics.tab

			cp  $raw_files/$F1/$F1.contigs-filtered.fasta $raw_files/all_fasta/$F1.fasta
			
			# sed -i 's/>.*/NNNNNNNNNN/g' $raw_files/all_fasta/$F1.fasta
			# sed -i "\$aNNNNNNNNNN" $raw_files/all_fasta/$F1.fasta
			# sed -i "1i "'>'$F1"" $raw_files/all_fasta/$F1.fasta
			else
			log "post-assembly statistics and coverting fasta files for... $F1 already finished"
			fi
	done 

###############################################################################
## Quality control by assembly-stat and quast
	for F1 in $(cat $sublist); do

		if [ ! -f $raw_files/$F1/$F1.raw-assembly.stat.tab ]; then 
			log "running assembly-stat for $F1"
			(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
			-t  $raw_files/$F1/contigs.fasta \
			>  $raw_files/$F1/$F1.raw-assembly.stat.tab) > /dev/null 2>&1

			(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
			-u  $raw_files/$F1/$F1.contigs-filtered.fasta \
			>>  $raw_files/$F1/$F1.filtered-assembly.stat.tab) > /dev/null 2>&1

			else
			log "assembly-stat for $F1 already finished"
		fi 

		if [ -f $raw_files/$F1/quast_raw_fasta ]; then
			log "running quast for $F1"
			( python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
			$raw_files/$F1/contigs.fasta \
			--output-dir  $raw_files/$F1/quast_raw_fasta ) > /dev/null 2>&1

			( python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
			$raw_files/$F1/$F1.contigs-filtered.fasta \
			--output-dir  $raw_files/$F1/quast_filtered_fasta ) > /dev/null 2>&1
			else
			log "quast for $F1 already finished"
		fi
		
		log "finished... step-4 assembly for... $F1"
	done 
###############################################################################