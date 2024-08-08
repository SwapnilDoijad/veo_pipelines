#!/bin/bash
#SBATCH --job-name 0046_genome_assembly_by_unicycler_only_nanopore
#SBATCH --partition=interactive
#SBATCH --output results/0046_genome_assembly_by_unicycler_only_nanopore/tmp/slurm/%j.out
#SBATCH --error results/0046_genome_assembly_by_unicycler_only_nanopore/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=20
###############################################################################
## header 
	pipeline=0046_genome_assembly_by_unicycler_only_nanopore
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
	sublist=results/$pipeline/tmp/lists/ABC
###############################################################################
## step-01: unicycler assembly
	# check short and long read, if both available
    for i in $(cat $sublist); do
		if [ ! -f $raw_files/$i/unicycler.log ] ; then 

			log "STARTED : long-read assembly for $i"

			python3.6 /home/groups/VEO/tools/unicycler/v0.5.0/unicycler-runner.py \
			-l $data_directory_fastq_path/"$i".fastq.gz \
			-o $raw_files/$i \
			-t $SLURM_CPUS_PER_TASK \
			--spades_path /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
			--racon_path /home/groups/VEO/tools/racon/v1.5.0/build/bin/racon \
			--tblastn_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/tblastn \
			--makeblastdb_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
			--keep 0

			echo "FINISHED : long-read assembly for $i"
			else
			echo "ALREADY FINISHED : long-read assembly for $i"
		fi
	done
###############################################################################
## if assembly fail due to miniasm (low coverage), then run without miniasm
    for i in $(cat $sublist); do
		if tail -n 1 "$raw_files/$i/unicycler.log" | grep -q "Error: miniasm assembly failed"; then

			log "STARTED : without miniasm long-read assembly for $i"

			python3.6 /home/groups/VEO/tools/unicycler/v0.5.0/unicycler-runner.py \
			-l $data_directory_fastq_path/"$i".fastq.gz \
			-o $raw_files/$i \
			--no_miniasm \
			--no_long_read_alignment \
			-t $SLURM_CPUS_PER_TASK \
			--spades_path /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
			--racon_path /home/groups/VEO/tools/racon/v1.5.0/build/bin/racon \
			--tblastn_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/tblastn \
			--makeblastdb_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
			--keep 0

			log "FINISHED : without miniasm long-read assembly for $i"

		fi 
	done
############################################################################### 
## step-02: post-assembly statistics and coverting fasta files

		(mkdir $wd/all_fasta ) > /dev/null 2>&1
		for i in $(cat $sublist); do
			if [ -f $raw_files/$i/assembly.fasta ] && [ ! -f $wd/all_fasta/$i.fasta ] ; then
				cp $raw_files/$i/assembly.fasta $wd/all_fasta/$i.fasta
			fi
		done

###############################################################################
## step-03: count the length of the fasta 
		if [ ! -f $wd/summary.tsv ] ; then 
			echo -e "id\tfasta_length" > $wd/summary.tsv
		fi 

		for i in $(cat $sublist ) ; do 
			if ! grep -q "$i" $wd/summary.tsv ; then
				if [ -f $raw_files/$i/assembly.fasta ]; then
					fasta_length=$( grep -v '^>' $raw_files/all_fasta/$i.fasta | tr -d '\n' | wc -c )
					echo -e "$i\t$fasta_length" >> $wd/summary.tsv
					else
					echo -e "$i\tassembly-failed" >> $wd/summary.tsv
				fi
			fi
		done 

###############################################################################
## footer
	log "FINISHED : $pipeline ------------------------"
###############################################################################
