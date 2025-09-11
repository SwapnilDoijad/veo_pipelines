#!/bin/bash
#SBATCH --job-name=0669_phage_taxonomy_by_phagGCN3
#SBATCH --partition=long,standard,short
#SBATCH --output=results/0669_phage_taxonomy_by_phagGCN3/tmp/slurm/%j.out
#SBATCH --error=results/0669_phage_taxonomy_by_phagGCN3/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0669_phage_taxonomy_by_phagGCN3
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	sublist=$wd/tmp/lists/ABC

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate phagcn_v20250806
###############################################################################
	log "STARTED :SBATCH : $pipeline -----------------------------"
###############################################################################
	for i in $(cat $sublist); do
		python $tools/phagcn3/v20250806/PhaGCN3/run_Speed_up.py \
		--contigs $fasta_directory/$i.fasta \
		--outpath $raw_files/$i \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/$i.run_Speed_up.tsv
	done 
###############################################################################
	log "ENDED :SBATCH : $pipeline -----------------------------"
###############################################################################