#!/bin/bash
#SBATCH --job-name=0450_genome_assembly_for_nanopore_long2shortReads_by_spades
#SBATCH --partition=standard
#SBATCH --output=results/0450_genome_assembly_for_nanopore_long2shortReads_by_spades/tmp/slurm/%j.out
#SBATCH --error=results/0450_genome_assembly_for_nanopore_long2shortReads_by_spades/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
#-- Command section ------------------------
	pipeline=0450_genome_assembly_for_nanopore_long2shortReads_by_spades
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -----------------------"
	sublist=results/$pipeline/tmp/lists/ABC
	fastq_path=$( grep my_fastq $parameters | awk '{print $2}' )
	
	echo "fastq_path: $fastq_path"
############################################################################### 
## step-02: run Spades assembler 
	for F1 in $(cat $sublist); do
		if [ ! -f $raw_files/$F1/$F1.fasta ]; then
			echo "running assembly for... $F1"
			(mkdir $raw_files/$F1) > /dev/null 2>&1
			python3.6 /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
			-s $fastq_path/"$F1".fastq.gz \
			-t $SLURM_CPUS_PER_TASK -m 200 --isolate -o $raw_files/$F1
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
			echo "assembly for... $F1 finished"
			else
			echo "assembly for... $F1 already finished" 
		fi
	done 

###############################################################################
## step-03: post-assembly statistics and coverting fasta files
	for F1 in $(cat $sublist); do
		if [ ! -f  $wd/all_fasta/$F1.fasta ]; then
			echo "running post-assembly statistics and coverting fasta files for... $F1"
			cp  $raw_files/$F1/contigs.fasta  $raw_files/$F1/$F1.fasta
			V1=$(grep -c ">"  $raw_files/$F1/$F1.fasta)
			grep -F ">"  $raw_files/$F1/$F1.fasta | sed -e 's/_/ /g' | sort -nrk 6 | awk '$6>=5.0 && $4>=1000 {print $0}' | sed -s 's/ /_/g' | sed -e 's/>//g' >  $raw_files/$F1/tmp/$F1.10-1000-filtered-contigs.csv
			perl /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl -f $raw_files/$F1/tmp/$F1.10-1000-filtered-contigs.csv $raw_files/$F1/$F1.fasta > $raw_files/$F1/$F1.contigs-filtered.fasta
			V2=$(grep -c ">"  $raw_files/$F1/$F1.contigs-filtered.fasta)
			V3=$(awk -F '_' '{ sum += $6; n++ } END { if (n > 0) print sum / n; }'  $raw_files/$F1/tmp/$F1.10-1000-filtered-contigs.csv)
			echo $V1 $V2 $V3 >  $raw_files/$F1/tmp/$F1.5_filtering_contigs.statistics.tab
			cp  $raw_files/$F1/$F1.contigs-filtered.fasta $wd/all_fasta/$F1.fasta
			sed -i 's/>.*/NNNNNNNNNN/g' $wd/all_fasta/$F1.fasta
			sed -i "\$aNNNNNNNNNN" $wd/all_fasta/$F1.fasta
			sed -i "1i "'>'$F1"" $wd/all_fasta/$F1.fasta
			else
			echo "post-assembly statistics and coverting fasta files for... $F1 already finished"
			fi
	done 

###############################################################################
## Quality control by assembly-stat and quast
	for F1 in $(cat $sublist); do

		if [ ! -f $raw_files/$F1/$F1.raw-assembly.stat.tab ]; then 
			echo "running assembly-stat for $F1"
			(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
			-t  $raw_files/$F1/contigs.fasta \
			>  $raw_files/$F1/$F1.raw-assembly.stat.tab) > /dev/null 2>&1

			(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
			-u  $raw_files/$F1/$F1.contigs-filtered.fasta \
			>>  $raw_files/$F1/$F1.filtered-assembly.stat.tab) > /dev/null 2>&1

			else
			echo "assembly-stat for $F1 already finished"
		fi 

		if [ -f $raw_files/$F1/quast_raw_fasta ]; then
			echo "running quast for $F1"
			( python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
			$raw_files/$F1/$F1.fasta \
			--output-dir  $raw_files/$F1/quast_raw_fasta ) > /dev/null 2>&1

			( python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
			$raw_files/$F1/$F1.contigs-filtered.fasta \
			--output-dir  $raw_files/$F1/quast_filtered_fasta ) > /dev/null 2>&1
			else
			echo "quast for $F1 already finished"
		fi
		
		echo "finished... step-4 assembly for..." $F1
	done 
###############################################################################