#!/bin/bash
#SBATCH --job-name=0775_amplicon_sequence_analysis_for_nanopore_by_nanoClust
#SBATCH --partition=standard,long,short,interactive,gpu,gpu-veo,gpu-test,fat
#SBATCH --output=results/0775_amplicon_sequence_analysis_for_nanopore_by_nanoClust/tmp/slurm/%j.out
#SBATCH --error=results/0775_amplicon_sequence_analysis_for_nanopore_by_nanoClust/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=24
###############################################################################
## step-01: preparation
    pipeline=0775_amplicon_sequence_analysis_for_nanopore_by_nanoClust
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    fastq_path=$(grep my_fastq_dir $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC

	conda activate nanoclust_v20260429 
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
	log "STARTED: nanoClust analysis for $i"

	for i in $(cat list.$pipeline.txt); do
		log "STARTED: nanoClust analysis for $i"
		
		setsid \
		nextflow run /vast/groups/VEO/tools/nanoclust/v20260429/NanoCLUST/main.nf \
		-c /vast/groups/VEO/tools/nanoclust/v20260429/NanoCLUST/nextflow.config \
		-profile conda \
		--reads "$fastq_path/$i.fastq" \
		--db /veodata/03/databases/nanoCLUST/v20260429/db/16S_ribosomal_RNA \
		--tax /veodata/03/databases/nanoCLUST/v20260429/db/taxdb \
		--outdir "${raw_files}/${i}" \
		--work-dir "${raw_files}/work/${i}" \
		-resume \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/$i.nanoclust.tsv
		summarize_log $resource_log/$i.nanoclust.tsv

		log "FINISHED: nanoClust analysis for $i"
	done

	log "FINISHED: nanoClust analysis for $i"

###############################################################################
	log "FINISHED: $pipeline -----------------------------"
###############################################################################
