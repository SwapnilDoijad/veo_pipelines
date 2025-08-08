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
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## run sourmash
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
	conda activate sourmash_v4.9.4

	for i in $(cat $sublist); do
		log "STARTED: $i"

		mkdir -p $raw_files/$i

		sourmash \
		sketch \
		dna \
		$fasta_directory/$i.fasta \
		--singleton \
		--name-from-first \
		-p k=21,scaled=100 \
		-o $raw_files/$i/phage.k21.s100.zip \
		& my_pid=$! 
		get_resource_stat $my_pid $wd/tmp/resource_log/$sublist.sourmash.sketch.tsv

		sourmash gather phage.k21.s100.zip viral-db.k21.s100.zip \
		--threshold-bp 3000 \
		-o $raw_files/$i/phage.k21.s100.gather.csv

		sourmash tax genome \
		--gather-csv phage.k21.s100.gather.csv \
		--taxonomy viral-db.tax.csv \
		--output-format csv_summary \
		-o $raw_files/$i/phage.k21.s100.tax.csv

	done

	conda deactivate
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean 
###############################################################################

