#!/bin/bash
#SBATCH --job-name=0777_amplicon_sequence_analysis_for_nanopore_by_nameco
#SBATCH --partition=standard
#SBATCH --output=results/0777_amplicon_sequence_analysis_for_nanopore_by_nameco/tmp/slurm/%j.out
#SBATCH --error=results/0777_amplicon_sequence_analysis_for_nanopore_by_nameco/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=24
###############################################################################
## step-01: preparation
    pipeline=0777_amplicon_sequence_analysis_for_nanopore_by_nameco
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    fastq_path=$(grep my_fastq_dir $parameters | awk '{print $2}')

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate nameco_v1.4.0
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
		
		setsid \
		nameco \
		--inp_dir ${fastq_path} \
		--out_dir ${raw_files} \
		--threads ${SLURM_CPUS_PER_TASK} \
		--fetch_db GTDB_232 \
		--db_path /veodata/03/databases/nameco/v20260528 \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/nameco.tsv
		summarize_log $resource_log/nameco.tsv

###############################################################################
	log "FINISHED: $pipeline -----------------------------"
###############################################################################
