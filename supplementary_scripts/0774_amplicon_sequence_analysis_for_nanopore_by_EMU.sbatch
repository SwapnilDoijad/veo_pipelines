#!/bin/bash
#SBATCH --job-name=0774_amplicon_sequence_analysis_for_nanopore_by_EMU
#SBATCH --partition=standard,long,short,interactive,gpu,gpu-veo,gpu-test,fat
#SBATCH --output=results/0774_amplicon_sequence_analysis_for_nanopore_by_EMU/tmp/slurm/%j.out
#SBATCH --error=results/0774_amplicon_sequence_analysis_for_nanopore_by_EMU/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=24
###############################################################################
## step-01: preparation
    pipeline=0774_amplicon_sequence_analysis_for_nanopore_by_EMU
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    fasta_path=$(grep my_fasta_dir $parameters | awk '{print $2}')
	database_path=$(grep my_database_path $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC
	
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate emu_v3.4.5 
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
	log "STARTED: emu abundance calculation for $i"

	for i in $(cat $sublist); do
		
		setsid \
		emu abundance \
		--type map-ont \
		--db $database_path \
		--output-dir $raw_files \
		--output-basename $i \
		--keep-counts \
		--keep-read-assignments \
		--threads $SLURM_CPUS_PER_TASK \
		${fasta_path}/$i.fasta \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/$i.emu.abundance.tsv
		summarize_log $resource_log/$i.emu.abundance.tsv

		sed -i 's/ /_/g' $raw_files/${i}_rel_abundance.tsv
		sed -i 's/\t\t/\tunassigned\t/g' $raw_files/${i}_rel_abundance.tsv

		mv $raw_files/${i}_read-assignment-distributions.tsv \
		$raw_files/distribution/

		mv $raw_files/${i}_rel-abundance.tsv \
		$raw_files/abundance/
	done

	log "FINISHED: emu abundance calculation for $i"

###############################################################################
	log "FINISHED: $pipeline -----------------------------"
###############################################################################