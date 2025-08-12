#!/bin/bash
#SBATCH --job-name=0661_phage_taxonomy_by_metabuli
#SBATCH --partition=standard,long
#SBATCH --output=results/0661_phage_taxonomy_by_metabuli/tmp/slurm/%j.out
#SBATCH --error=results/0661_phage_taxonomy_by_metabuli/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0661_phage_taxonomy_by_metabuli
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )

	seq_mode=$( grep my_seq-mode $parameters | awk '{print $2}')
	min_score=$( grep my_min-score $parameters | awk '{print $2}')
	min_sp_score=$( grep my_min-sp-score $parameters | awk '{print $2}')
	tie_ratio=$( grep my_tie-ratio $parameters | awk '{print $2}')

	sublist=$wd/tmp/lists/ABC
	databases=/veodata/03/databases/metabuli/v20250312/refseq_prokaryote_virus
	
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate metabuli_v1.1.1
	echo "$seq_mode $min_score $min_sp_score $tie_ratio"
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: file and directory preparation
	for i in $(cat $sublist); do
		log "STARTED: classify : $i"

		metabuli \
		classify \
		--seq-mode ${seq_mode} \
		--max-ram 100 \
		--min-score ${min_score} \
		--min-sp-score ${min_sp_score} \
		--tie-ratio ${tie_ratio} \
		--threads $SLURM_CPUS_PER_TASK \
		$fasta_directory/$i.fasta \
		$databases \
		$wd/raw_files/$i/ \
		$i \
		--lineage 1 \
		& my_pid=$!
		get_resource_stat $my_pid $resource_log/$i.metabuli.classify.tsv

		log "STARTED: ictv-format : $i"

		# metabuli \
		# ictv-format \
		# $wd/raw_files/$i/${i}_classifications.tsv \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.metabuli.ictv-format.tsv

	done
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean
###############################################################################

