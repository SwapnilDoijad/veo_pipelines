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

	ictv_challenge_classifications=/vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/data/ictv-challenge.classifications.csv
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	task=$(grep my_task $parameters | awk '{print $2}')
	sublist=$wd/tmp/lists/ABC
	kmer=$(grep my_kmer $parameters | awk '{print $2}')
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## databases 
    # "DNA-k21-sc50": "https://osf.io/download/8qxa2/",
    # "DNA-k31-sc50": "https://osf.io/download/n8dgy/",
    # "skipm2n3-k24-sc50": "https://osf.io/download/u3ftq/",
    # "skipm2n3-k27-sc50": "https://osf.io/download/mjqdg/",

## parameters for sourmash
	# "DNA-k21-sc50": "-p dna,k=21,scaled=50,abund",
    # "DNA-k31-sc50": "-p dna,k=31,scaled=50,abund",
    # "skipm2n3-k24-sc50": "-p skipm2n3,k=24,scaled=50,abund",
    # "skipm2n3-k27-sc50": "-p skipm2n3,k=27,scaled=50,abund",

	if [ $kmer == "21" ]; then
		model="DNA"
	elif [ $kmer == "31" ]; then
		model="DNA"
	elif [ $kmer == "24" ]; then
		model="skipm2n3"
	elif [ $kmer == "27" ]; then
		model="skipm2n3"
	else
		log "ERROR: Invalid k-mer size specified: $kmer. Exiting." && exit 1
	fi
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
	-p ${model},k=${kmer},scaled=50,abund \
	-o $raw_files/ictv-challenge.zip \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/sourmash.scripts.manysketch.tsv

	sourmash \
	scripts \
	fastmultigather \
	$raw_files/ictv-challenge.zip \
	/veodata/03/databases/sourmash/vmr_MSL39_v4_k${kmer} \
	-m ${model} \
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
	$ictv_challenge_classifications \
	$raw_files/ictv-challenge.sourmash.csv \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/tg-to-challengeformat.tsv

	conda deactivate
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean 
###############################################################################

