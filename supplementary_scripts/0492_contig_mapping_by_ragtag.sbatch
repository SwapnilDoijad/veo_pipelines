#!/bin/bash
#SBATCH --job-name=0492_contig_mapping_by_ragtag
#SBATCH --partition=interactive
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
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate ragtag_v2.1.0 
	
	while IFS=$'\t' read -r query ref; do 
		log "STARTED: $query $ref"

		query_id=$(echo $query | awk -F'/' '{print $NF}' | sed 's/.fasta//g')

		ragtag.py scaffold \
		$ref $query \
		-u \
		-t $SLURM_CPUS_PER_TASK \
		-o $raw_files/$query_id

		cp $raw_files/$query_id/ragtag.scaffold.fasta \
		$wd/all_fasta/$i.fasta

		log "DONE: $query $ref"
	done < $sublist

############################################################################### 