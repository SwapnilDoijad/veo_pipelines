#!/bin/bash
#SBATCH --job-name=0662_phage_taxonomy_by_vanjari
#SBATCH --partition=standard,long
#SBATCH --output=results/0662_phage_taxonomy_by_vanjari/tmp/slurm/%j.out
#SBATCH --error=results/0662_phage_taxonomy_by_vanjari/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0662_phage_taxonomy_by_vanjari
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate vanjari_v250814_barbet

###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: file and directory preparation

	# Generage results for single models
	vanjari \
	--input $fasta_directory/ \
	--output-csv $raw_files/vanjari-0.1.csv \
	--memmap-array-path $raw_files/embeddings.npy \
	--memmap-index $raw_files/embeddings.txt \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/$i.vanjari.tsv

	vanjari-fast \
	--input $fasta_directory/ \
	--output-csv $raw_files/vanjari-fast-0.1.csv \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/$i.vanjari.fast.tsv
	# # Generate results for ensemble
	# vanjari-tools ensemble-csvs --input ictv-challenge/vanjari-0.1.csv --input ictv-challenge/vanjari-fast-0.1.csv --output ictv-challenge/vanjari-ensemble-0.1.csv

	# # Set the threshold for the all results to 0.5
	# vanjari-tools increase-threshold --input ictv-challenge/vanjari-0.1.csv --output ictv-challenge/vanjari-0.1-threshold0.5.csv --threshold 0.5
	# vanjari-tools increase-threshold --input ictv-challenge/vanjari-fast-0.1.csv --output ictv-challenge/vanjari-fast-0.1-threshold0.5.csv --threshold 0.5
	# vanjari-tools increase-threshold --input ictv-challenge/vanjari-ensemble-0.1.csv --output ictv-challenge/vanjari-ensemble-0.1-threshold0.5.csv --threshold 0.5


###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean
###############################################################################

