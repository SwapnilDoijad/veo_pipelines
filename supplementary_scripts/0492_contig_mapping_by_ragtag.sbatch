#!/bin/bash
#SBATCH --job-name=0492_contig_mapping_by_ragtag
#SBATCH --partition=short,standard,long,interactive,gpu,gpu-veo,gpu-test
#SBATCH --output=results/0492_contig_mapping_by_ragtag/tmp/slurm/%j.out
#SBATCH --error=results/0492_contig_mapping_by_ragtag/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## step-00: preparation
    pipeline=0492_contig_mapping_by_ragtag
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
############################################################################### 
	log "STARTED : $pipeline for $sublist" 
###############################################################################
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate ragtag_v2.1.0 
	
	while IFS=$'\t' read -r query ref; do 
		if [ ! -f $wd/all_fasta/$query_id.fasta ]; then
			log "STARTED: $query $ref"

			query_id=$(echo $query | awk -F'/' '{print $NF}' | sed 's/.fasta//g')

			ragtag.py scaffold \
			$ref $query \
			-u \
			-t $SLURM_CPUS_PER_TASK \
			-o $raw_files/$query_id

			cp $raw_files/$query_id/ragtag.scaffold.fasta \
			$wd/all_fasta/$query_id.fasta

			unorganised_contigs=$( get_fasta_contigs_length_all $query | awk '{print $2}' )
			organised_contigs=$( get_fasta_contigs_length_all $wd/all_fasta/$query_id.fasta | awk '{print $2, $3}' )

			if [[ -n $unorganised_contigs && -n $organised_contigs ]]; then
				echo $unorganised_contigs $organised_contigs
				echo -e "$query_id\t$unorganised_contigs\t$organised_contigs" | tr ' ' '\t' >> $wd/summary.tsv
			fi

			log "DONE: $query $ref"
		else
			log "ALREADY FINISHED: $query $ref"
		fi
	done < $sublist

############################################################################### 
	log "FINISHED : $pipeline for $sublist" && clean
###############################################################################