#!/bin/bash
#SBATCH --job-name=0412_genome_assembly_polish_by_polypolish
#SBATCH --partition=interactive
#SBATCH --output=results/0412_genome_assembly_polish_by_polypolish/tmp/slurm/%j.out
#SBATCH --error=results/0412_genome_assembly_polish_by_polypolish/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=25
############################################################################### 
## 00: preparations
    pipeline=0412_genome_assembly_polish_by_polypolish
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	sublist=$wd/tmp/lists/ABC
	polypolish=/home/groups/VEO/tools/polypolish/v0.6.0/polypolish 
	# output_dir=$(grep -w "my_output_dir" $parameters | awk '{print $2}')

	mkdir -p $output_dir > /dev/null 2>&1
###############################################################################
	while IFS=$'\t' read -r assembly illumina_R1 illumina_R2 sam_file ; do
		id=$(basename $assembly | cut -d'.' -f1)

		log "id: $id"
		log "assembly: $assembly"
		log "illumina_R1: $illumina_R1"
		log "illumina_R2: $illumina_R2"
		log "sam_file: $sam_file"

		$polypolish polish \
		$assembly \
		$sam_file \
		> $raw_files/$id.fasta \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/$id.unicycler.tsv 

	done < $sublist
###############################################################################