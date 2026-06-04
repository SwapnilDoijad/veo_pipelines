#!/bin/bash
#SBATCH --job-name=0656_phage_taxonomy_by_sourmash
#SBATCH --partition=standard,long
#SBATCH --output=results/0656_phage_taxonomy_by_sourmash/tmp/slurm/%j.out
#SBATCH --error=results/0656_phage_taxonomy_by_sourmash/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0656_phage_taxonomy_by_sourmash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	task=$(grep my_task $parameters | awk '{print $2}')
	sublist=$wd/tmp/lists/ABC
	kmer=$(grep my_kmer $parameters | awk '{print $2}')
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## run sourmash	
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
	conda activate sourmash_v4.9.4

	python3 $tools/sourmash/2024-ictv-challenge-sourmash/scripts/challengedir-to-csvinput.py \
	$fasta_directory \
	$raw_files/dataset_challenge.fromfile.csv \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/challengedir-to-csvinput.tsv

	sourmash \
	scripts \
	manysketch \
	$raw_files/dataset_challenge.fromfile.csv \
	-p skipm2n3,k=${kmer},scaled=50,abund \
	-o $raw_files/ictv-challenge.zip \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/sourmash.scripts.manysketch.tsv

	sourmash \
	scripts \
	fastmultigather \
	$raw_files/ictv-challenge.zip \
	/veodata/03/databases/sourmash/vmr_MSL39_v4 \
	-m skipm2n3 \
	-k ${kmer} \
	--scaled 50 \
	--threshold-bp 200 \
	-o $raw_files/ictv-challenge.fmg.csv \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/sourmash.scripts.fastmultigather.tsv

  	sourmash \
	tax \
	genome \
	-t $tools/sourmash/2024-ictv-challenge-sourmash/vmr_MSL39_v4.lineages.csv.gz \
	-g $raw_files/ictv-challenge.fmg.csv \
	--ictv -F csv_summary \
    --ani-threshold 0.75 \
	--output-base ictv-challenge \
    --output-dir $raw_files \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/sourmash.tax.genome.tsv

	python3 $tools/sourmash/2024-ictv-challenge-sourmash/scripts/tg-to-challengeformat.py \
	$raw_files/ictv-challenge.classifications.csv \
	$raw_files/ictv-challenge.sourmash.csv \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/tg-to-challengeformat.tsv

	conda deactivate
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean 
###############################################################################

