#!/bin/bash
#SBATCH --job-name=0668_phage_taxonomy_by_ictvNR
#SBATCH --partition=long,standard
#SBATCH --output=results/0668_phage_taxonomy_by_ictvNR/tmp/slurm/%j.out
#SBATCH --error=results/0668_phage_taxonomy_by_ictvNR/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0668_phage_taxonomy_by_ictvNR
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	
	export PATH=/home/groups/VEO/tools/mmseq/v17-b804f/mmseqs/bin/:$PATH
	export PATH=/home/groups/VEO/tools/pixi/v250822/pixi/bin:$PATH
###############################################################################
	log "STARTED :SBATCH : $pipeline -----------------------------"
###############################################################################
	git clone https://github.com/apcamargo/ictv-taxonomy-challenge-nr.git
	mv ictv-taxonomy-challenge-nr $raw_files
	cd $raw_files/ictv-taxonomy-challenge-nr

	# pixi run pipeline \
	# & my_pid=$!
	# get_resource_stat $my_pid ../../tmp/resource_log/pixi.ictvNR.tsv

	# pixi run pipeline \
	# & my_pid=$!
	# accurate_log_usage $my_pid ../../tmp/resource_log/pixi.ictvNR.accurate.tsv 1

	setsid pixi run pipeline & my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ../../tmp/resource_log/pixi.ictvNR.accurate.tsv 1

###############################################################################
	log "ENDED :SBATCH : $pipeline -----------------------------"
###############################################################################