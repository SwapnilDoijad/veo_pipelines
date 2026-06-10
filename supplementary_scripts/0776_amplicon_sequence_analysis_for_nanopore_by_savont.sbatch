#!/bin/bash
#SBATCH --job-name=0776_amplicon_sequence_analysis_for_nanopore_by_savont
#SBATCH --partition=standard
#SBATCH --output=results/0776_amplicon_sequence_analysis_for_nanopore_by_savont/tmp/slurm/%j.out
#SBATCH --error=results/0776_amplicon_sequence_analysis_for_nanopore_by_savont/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=24
###############################################################################
## step-01: preparation
    pipeline=0776_amplicon_sequence_analysis_for_nanopore_by_savont
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    fastq_path=$(grep my_fastq_dir $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate savont_v0.3.2
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
	log "STARTED: nanoClust analysis for $i"

	for i in $(cat list.$pipeline.txt); do
		log "STARTED: nanoClust analysis for $i"
		
		setsid \
		savont asv \
		"$fastq_path/$i.fastq" \
		-o "${raw_files}/${i}" \
		-t $SLURM_CPUS_PER_TASK \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/$i.savont.asv.tsv
		summarize_log $resource_log/$i.savont.asv.tsv

		setsid \
		savont classify \
		-i "${raw_files}/${i}" \
		-o "${raw_files}/${i}" \
		--silva-db /veodata/03/databases/savont/v20260202/silva_db/ \
		-t $SLURM_CPUS_PER_TASK \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/$i.savont.classify.tsv
		summarize_log $resource_log/$i.savont.classify.tsv
		

		log "FINISHED: nanoClust analysis for $i"
	done

	log "FINISHED: nanoClust analysis for $i"

###############################################################################
	log "FINISHED: $pipeline -----------------------------"
###############################################################################
