#!/bin/bash
#SBATCH --job-name=0226_gene_detection_abr_by_resfinder
#SBATCH --partition=standard,long
#SBATCH --output=results/0226_gene_detection_abr_by_resfinder/tmp/slurm/%j.out
#SBATCH --error=results/0226_gene_detection_abr_by_resfinder/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-01: preparation
    pipeline=0226_gene_detection_abr_by_resfinder
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
	mamba init &&  source ~/.bashrc && mamba activate resfinder_v4.6.0 
    
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	data_type=$(grep "my_data_type" $parameters | awk '{print $2}')
###############################################################################
## step-02: 
	log "STARTED : $pipeline : $sublist"
	for i in $(cat $sublist); do
		log "STARTED : $i"
		mkdir $raw_files/$i/ > /dev/null 2>&1

		if [ $data_type == "nanopore" ]; then
		if [ ! -f $raw_files/$i/$i.virulence-gene-blast.tmp ]; then
			log "STARTED : $pipeline : $i : $data_type"

			python -m resfinder \
			-acq \
			--nanopore \
			-ifa $fasta_directory/$i.fasta \
			-o $raw_files/$i/ \
			--db_path_res /veodata/03/databases/resfinder/20250120/db_resfinder

			elif [ $data_type == "illumina" ]; then
			log "STARTED : $pipeline : $i : $data_type"

			python -m resfinder \
			-acq \
			-ifa $fasta_directory/$i.fasta \
			-o $raw_files/$i/ \
			--db_path_res /veodata/03/databases/resfinder/20250120/db_resfinder

            log "FINISHED : $i"
			else
			log "ALREADY FINISHED : $i"
		fi
		fi
		log "FINISHED : $i"
	done 
	log "FINISHED : $pipeline : $sublist"
###############################################################################