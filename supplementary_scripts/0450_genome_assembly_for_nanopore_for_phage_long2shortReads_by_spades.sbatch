#!/bin/bash
#SBATCH --job-name=0450_genome_assembly_for_nanopore_for_phage_long2shortReads_by_spades
#SBATCH --partition=short
#SBATCH --output=results/0450_genome_assembly_for_nanopore_for_phage_long2shortReads_by_spades/tmp/slurm/%j.out
#SBATCH --error=results/0450_genome_assembly_for_nanopore_for_phage_long2shortReads_by_spades/tmp/slurm/%j.err
#SBATCH --mem=20G
#SBATCH --cpus-per-task=8
###############################################################################
## step-00: preparation
	pipeline=0450_genome_assembly_for_nanopore_for_phage_long2shortReads_by_spades
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -----------------------"
	sublist=results/$pipeline/tmp/lists/ABC
	fastq_path=$( cat $parameters | grep -v "#" | grep my_fastq | awk '{print $2}' )
	ref_seq=$( cat $parameters | grep -v "#" | grep my_ref_seq | awk '{print $2}' )
	start_seq=$( cat $parameters | grep -v "#" | grep my_start_seq | awk '{print $2}' )
	end_seq=$( cat $parameters | grep -v "#" | grep my_end_seq | awk '{print $2}' )
	
	log "fastq_path: $fastq_path"
	log "ref_seq: $ref_seq"
	log "start_seq: $start_seq"
	log "end_seq: $end_seq"

############################################################################### 
## step-01: run Spades assembler 
	for i in $(cat $sublist); do
		if [ ! -d $raw_files/$i ]; then
			log "running assembly for... $i"
			(mkdir $raw_files/$i) > /dev/null 2>&1
			python3.6 /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
			-s $fastq_path/"$i".fastq.gz \
			-t $SLURM_CPUS_PER_TASK -m 200 --isolate -o $raw_files/$i
			(rm -r $raw_files/$i/K21) > /dev/null 2>&1
			(rm -r $raw_files/$i/K33) > /dev/null 2>&1
			(rm -r $raw_files/$i/K55) > /dev/null 2>&1
			(rm -r $raw_files/$i/K77) > /dev/null 2>&1
			(rm -r $raw_files/$i/K99) > /dev/null 2>&1
			(rm -r $raw_files/$i/K127) > /dev/null 2>&1
			(rm -r $raw_files/$i/corrected) > /dev/null 2>&1
			(rm -r $raw_files/$i/configs) > /dev/null 2>&1
			(rm -r $raw_files/$i/misc) > /dev/null 2>&1
			(rm -r $raw_files/$i/tmp) > /dev/null 2>&1
			(mkdir $raw_files/$i/tmp) > /dev/null 2>&1
			log "assembly for... $i finished"
			else
			log "assembly for... $i already finished" 
		fi
	done 
############################################################################### 
## step-02: Quality control by assembly-stat and quast
	mkdir $wd/all_fasta > /dev/null 2>&1
	mkdir $wd/all_fasta_rearranged > /dev/null 2>&1

	for i in $(cat $sublist); do
		if [ -f $raw_files/$i/contigs.fasta ] ; then
			source /home/groups/VEO/tools/biopython/myenv/bin/activate
			if [ ! -f $wd/all_fasta/$i.fasta ] ; then
				log "STARTED: $i: find_and_trim_overalp_in_multifasta"
				python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/find_and_trim_overalp_in_multifasta.py \
				-i $raw_files/$i/contigs.fasta \
				-o $raw_files/$i/$i.fasta 

				log "STARTED: $i: filter_fasta_based_on_length"
				python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/filter_fasta_based_on_length.py \
				-i $raw_files/$i/$i.fasta \
				-o $raw_files/$i/$i.filtered.fasta \
				-l 100

				cp $raw_files/$i/$i.filtered.fasta $wd/all_fasta/$i.fasta
			fi
			deactivate

			if [ ! -f $raw_files/$i/$i.filtered-assembly.stat.tab ]; then 
				log "running assembly-stat for $i"
				(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
				-t $raw_files/$i/contigs.fasta \
				>  $raw_files/$i/$i.raw-assembly.stat.tab) > /dev/null 2>&1

				sed -i "s|results/0450_genome_assembly_for_nanopore_for_phage_long2shortReads_by_spades/raw_files/||g" $raw_files/$i/$i.raw-assembly.stat.tab
				sed -i "s|/contigs.fasta||g" $raw_files/$i/$i.raw-assembly.stat.tab

				(/home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
				-t $raw_files/$i/$i.filtered.fasta \
				>  $raw_files/$i/$i.filtered-assembly.stat.tab) > /dev/null 2>&1

				sed -i "s|results/0450_genome_assembly_for_nanopore_for_phage_long2shortReads_by_spades/raw_files/||g" $raw_files/$i/$i.filtered-assembly.stat.tab
				sed -i "s|/contigs.fasta||g" $raw_files/$i/$i.filtered-assembly.stat.tab

				else
				log "assembly-stat for $i already finished"
			fi 

			# if [ -d $raw_files/$i/quast_raw_fasta ]; then
				# log "running quast for $i"
				# ( python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
				# $raw_files/$i/$i.filtered.fasta \
				# --output-dir  $raw_files/$i/quast_raw_fasta ) > /dev/null 2>&1

			# 	else
			# 	log "quast for $i already finished"
			# fi
			
			log "finished... step-4 assembly for..." $i
			else
			log "SKIPPING: $i aassembly failed"
		fi
	done 

###############################################################################
## step-03: Quality control by assembly-stat and quast


		if [ ! -f $wd/summary.raw.tsv ] || ! grep -Pq "^filename\ttotal_length\tnumber\tmean_length\tlongest\tshortest\tN_count\tGaps\tN50\tN50n\tN70\tN70n\tN90\tN90n" $wd/summary.raw.tsv; then
			echo -e "filename\ttotal_length\tnumber\tmean_length\tlongest\tshortest\tN_count\tGaps\tN50\tN50n\tN70\tN70n\tN90\tN90n" > $wd/summary.raw.tsv
		fi

		for i in $(cat $sublist); do
			if [ -f $raw_files/$i/$i.fasta ] ; then
				if ! grep -q "$i" $wd/summary.raw.tsv ; then
					awk 'NR>1 {print $0}' $raw_files/$i/$i.raw-assembly.stat.tab >> $wd/summary.raw.tsv
					else
					echo -e "$i\tassembly_failed" >> $wd/summary.raw.tsv
				fi
			fi
		done 



		if [ ! -f $wd/summary.filtered.tsv ] || ! grep -Pq "^filename\ttotal_length\tnumber\tmean_length\tlongest\tshortest\tN_count\tGaps\tN50\tN50n\tN70\tN70n\tN90\tN90n" $wd/summary.filtered.tsv; then
			echo -e "filename\ttotal_length\tnumber\tmean_length\tlongest\tshortest\tN_count\tGaps\tN50\tN50n\tN70\tN70n\tN90\tN90n" > $wd/summary.filtered.tsv
		fi

		for i in $(cat $sublist); do
			if [ -f $raw_files/$i/$i.fasta ] ; then
				if ! grep -q "$i" $wd/summary.filtered.tsv ; then
					awk 'NR>1 {print $0}' $raw_files/$i/$i.filtered-assembly.stat.tab >> $wd/summary.filtered.tsv
					else
					echo -e "$i\tassembly_failed" >> $wd/summary.filtered.tsv
				fi
			fi
		done 


############################################################################### 
## step-04: arrange contigs as per reference
	if [ -n "$ref_seq" ]; then 
		source /home/groups/VEO/tools/biopython/myenv/bin/activate
		for i in $(cat $sublist); do
			if [ -f $wd/all_fasta/$i.fasta ] ; then
				log "RUNNING: contigs arrangement as per reference for $i "
				( rm -rf /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13/$i ) > /dev/null 2>&1

				WorDir=$(echo $PWD)

				cd /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13
				
				java -Xmx5000m -cp Mauve.jar org.gel.mauve.contigs.ContigOrderer \
				-output $i \
				-ref $WorDir/$ref_seq \
				-draft $WorDir/$wd/all_fasta/$i.fasta
		
				cd $WorDir

				Var1=$( ls /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13/$i/ | sort -r | head -1 )
				cp /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13/$i/$Var1/$i.fasta $raw_files/$i/$i.aligned.fasta
				sed 's/>.*/NNNNNNNNNN/g' $raw_files/$i/$i.aligned.fasta > $wd/all_fasta/$i.fasta
				sed -i "1i "'>'$i"" $wd/all_fasta/$i.fasta
				sed -i '2d' $wd/all_fasta/$i.fasta
				( rm -rf /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13/$i ) > /dev/null 2>&1

				python3.6 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/reformat_fasta.py \
				-i $wd/all_fasta/$i.fasta \
				-o $wd/all_fasta/$i.2.fasta

				python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/find_and_trim_overalp_in_multifasta.py \
				-i $wd/all_fasta/$i.2.fasta \
				-o $wd/all_fasta/$i.fasta
				
				rm -rf $wd/all_fasta/$i.2.fasta > /dev/null 2>&1

				if [ -n "$start_seq" ]; then
					python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/rearrange_genome_starting_from_desired_sequence.py \
					-i $wd/all_fasta/$i.fasta \
					-o $wd/all_fasta_rearranged/$i.fasta \
					-s $start_seq
				fi
	
				if [ -f $wd/all_fasta_rearranged/$i.fasta ]; then 
					length=$(python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/get_fasta_length.py -i $wd/all_fasta_rearranged/$i.fasta)
					elif [ -f $wd/all_fasta/$i.fasta ] ; then
					length=$(python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/get_fasta_length.py -i $wd/all_fasta/$i.fasta)
				fi

				echo -e "$i\t$length" >> $wd/summary.final_rearranged_genome.tsv


			fi 
		done

		deactivate
		else
		log "SKIPPING: reference sequence not provided"
	fi
###############################################################################

## discarded code
	# ## step-02: post-assembly statistics and converting fasta files
	# 	mkdir $wd/all_fasta > /dev/null 2>&1
	# 	for i in $(cat $sublist); do
	# 		if [ ! -f  $wd/all_fasta/$i.fasta ]; then
	# 			log "running post-assembly statistics and coverting fasta files for... $i"
	# 			cp  $raw_files/$i/contigs.fasta  $raw_files/$i/$i.fasta
	# 			V1=$(grep -c ">"  $raw_files/$i/$i.fasta)
	# 			grep -F ">"  $raw_files/$i/$i.fasta | sed -e 's/_/ /g' | sort -nrk 6 | awk '$6>=5.0 && $4>=1000 {print $0}' | sed -s 's/ /_/g' | sed -e 's/>//g' >  $raw_files/$i/tmp/$i.10-1000-filtered-contigs.csv
	# 			perl /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl -f $raw_files/$i/tmp/$i.10-1000-filtered-contigs.csv $raw_files/$i/$i.fasta > $raw_files/$i/$i.contigs-filtered.fasta
	# 			V2=$(grep -c ">"  $raw_files/$i/$i.contigs-filtered.fasta)
	# 			V3=$(awk -F '_' '{ sum += $6; n++ } END { if (n > 0) print sum / n; }'  $raw_files/$i/tmp/$i.10-1000-filtered-contigs.csv)
	# 			log $V1 $V2 $V3 >  $raw_files/$i/tmp/$i.5_filtering_contigs.statistics.tab
	# 			cp  $raw_files/$i/$i.contigs-filtered.fasta $wd/all_fasta/$i.fasta
	# 			sed -i 's/>.*/NNNNNNNNNN/g' $wd/all_fasta/$i.fasta
	# 			sed -i "\$aNNNNNNNNNN" $wd/all_fasta/$i.fasta
	# 			sed -i "1i "'>'$i"" $wd/all_fasta/$i.fasta
	# 			else
	# 			log "post-assembly statistics and coverting fasta files for... $i already finished"
	# 			fi
	# 	done 
###############################################################################