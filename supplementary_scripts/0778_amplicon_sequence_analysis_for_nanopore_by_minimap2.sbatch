#!/bin/bash
#SBATCH --job-name=0778_amplicon_sequence_analysis_for_nanopore_by_minimap2
#SBATCH --partition=standard
#SBATCH --output=results/0778_amplicon_sequence_analysis_for_nanopore_by_minimap2/tmp/slurm/%j.out
#SBATCH --error=results/0778_amplicon_sequence_analysis_for_nanopore_by_minimap2/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=24
###############################################################################
## step-01: preparation
    pipeline=0778_amplicon_sequence_analysis_for_nanopore_by_minimap2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	
	sublist=${wd}/tmp/lists/ABC
    fastq_path=$(grep my_fastq_dir $parameters | awk '{print $2}')

	minimap2=/home/groups/VEO/tools/minimap2/v2.26/minimap2
	database=/veodata/03/databases/silva/silva_16s_138.2/SILVA_138.2_SSURef_NR99_tax_silva_trunc_dna.fasta

###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
		
	for i in $(cat $sublist); do
		log "STARTED: minimap2 analysis for $i"

			## First time: create minimap2 index for 16s database
				# ${minimap2} \
				# -d ${database}.mmi \
				# $database 

			if [ ! -f ${raw_files}/${i}_vs_16s.paf ]; then
				setsid \
				${minimap2} -x map-ont \
				--secondary=no \
				-t $SLURM_CPUS_PER_TASK \
				${database}.mmi \
				${fastq_path}/${i}.fastq.gz \
				> ${raw_files}/${i}_vs_16s.paf \
				& my_pid=$!
				pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
				accurate_log_usage_by_pgid "$pgid" $resource_log/${i}.minimap2.tsv
				summarize_log $resource_log/${i}.minimap2.tsv
			fi

			if [ ! -f ${raw_files}/${i}_vs_16s.paf.taxmap.tsv ]; then
				setsid \
				python3 ${suppl_scripts}/${pipeline}.taxmap.py \
				-i ${raw_files}/${i}_vs_16s.paf \
				-o ${raw_files}/${i}_vs_16s.paf.taxmap.tsv \
				& my_pid=$!
				pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
				accurate_log_usage_by_pgid "$pgid" $resource_log/${i}.taxmap.tsv
				summarize_log $resource_log/${i}.taxmap.tsv
			fi

		done
###############################################################################
	log "FINISHED: $pipeline -----------------------------"
############################################################################---
