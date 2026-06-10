#!/bin/bash
#SBATCH --job-name=0670_phage_taxonomy_by_ictv_genomad
#SBATCH --partition=long,standard
#SBATCH --output=results/0670_phage_taxonomy_by_ictv_genomad/tmp/slurm/%j.out
#SBATCH --error=results/0670_phage_taxonomy_by_ictv_genomad/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0670_phage_taxonomy_by_ictv_genomad
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	export PATH=/home/groups/VEO/tools/mmseq/v17-b804f/mmseqs/bin/:$PATH
	export PATH=/home/groups/VEO/tools/pixi/v250822/pixi/bin:$PATH
###############################################################################
	log "STARTED :SBATCH : $pipeline -----------------------------"
###############################################################################
	git clone https://github.com/apcamargo/ictv-taxonomy-challenge-genomad.git
	mv ictv-taxonomy-challenge-nr $raw_files
	cd $raw_files/ictv-taxonomy-challenge-nr

	setsid pixi run pipeline & my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ../../tmp/resource_log/pixi.ictvNR.accurate.tsv 1

###############################################################################
	log "ENDED :SBATCH : $pipeline -----------------------------"
###############################################################################