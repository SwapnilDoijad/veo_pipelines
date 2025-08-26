#!/bin/bash
#SBATCH --job-name=0660_phage_taxonomy_by_vcat
#SBATCH --partition=standard,long
#SBATCH --output=results/0660_phage_taxonomy_by_vcat/tmp/slurm/%j.out
#SBATCH --error=results/0660_phage_taxonomy_by_vcat/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0660_phage_taxonomy_by_vcat
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	sublist=$wd/tmp/lists/ABC
	databases_path=/veodata/03/databases/vcat/v250811/msl40v1

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate vcat_v20250806
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: file and directory preparation
	for i in $(cat $sublist); do
		log "STARTED: $i"

		vcat \
		contigs \
		-i $fasta_directory/$i.fasta \
		-o $raw_files/$i/ \
		-d $databases_path \
		--ani 0.95 \
		--qcov 0.85 \
		--batch 1000 \
		-j $SLURM_CPUS_PER_TASK \
		-n \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/$i.vcat.contigs.tsv

	done
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean
###############################################################################
