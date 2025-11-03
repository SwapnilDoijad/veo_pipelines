#!/bin/bash
#SBATCH --job-name=0494_contig_rearrange_from_same_gene_by_circlator
#SBATCH --partition=short,standard,long,interactive,gpu,gpu-veo,gpu-test
#SBATCH --output=results/0494_contig_rearrange_from_same_gene_by_circlator/tmp/slurm/%j.out
#SBATCH --error=results/0494_contig_rearrange_from_same_gene_by_circlator/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## step-00: preparation
    pipeline=0494_contig_rearrange_from_same_gene_by_circlator
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	start_gene_path=$( grep "start_gene" $parameters | awk '{print $2}' )
	start_gene_name=$( basename $start_gene_path | sed 's/\.fasta//g' )

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate circlator_v36
############################################################################### 
	log "STARTED : $pipeline for $sublist" 
###############################################################################

	for i in $(cat $sublist); do

		log "STARTED: $i"

		mkdir -p $raw_files/$i

		circlator fixstart \
		--genes_fa $start_gene_path \
		$fasta_dir/$i.fasta \
		$raw_files/$i/${i}_${start_gene_name}

		cp $raw_files/$i/${i}_${start_gene_name}.fasta \
		$wd/all_fasta_${start_gene_name}_rearranged_by_circlator/${i}_${start_gene_name}.fasta

	done

############################################################################### 
	log "FINISHED : $pipeline for $sublist" #&& clean
###############################################################################