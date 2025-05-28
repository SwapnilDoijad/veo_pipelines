#!/bin/bash
#SBATCH --job-name=0493_genome_assembly_QC_by_inspector
#SBATCH --partition=standard,long,interactive
#SBATCH --output=results/0493_genome_assembly_QC_by_inspector/tmp/slurm/%j.out
#SBATCH --error=results/0493_genome_assembly_QC_by_inspector/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## step-00: preparation
    pipeline=0493_genome_assembly_QC_by_inspector
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
############################################################################### 
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh &&
	conda activate inspector_v.1.3.1 &&
	export PATH=/home/groups/VEO/tools/inspector/v1.3.1/Inspector/:$PATH

	while IFS=$'\t' read -r contig fastq; do 

		contig_id=$(basename $(dirname "$contig"))
	
		log "STARTED: $contig_id $fastq"
		inspector.py \
		-c $contig \
		-r $fastq \
		-d nanopore \
		--min_contig_length 1000 \
		--min_contig_length_assemblyerror 1000 \
		-t $SLURM_CPUS_PER_TASK \
		-o $raw_files/$contig_id

		log "DONE: $contig_id $fastq"
	done < $sublist

############################################################################### 