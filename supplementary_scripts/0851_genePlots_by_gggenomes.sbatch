#!/bin/bash
#SBATCH --job-name=0851_genePlots_by_gggenomes
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu-test,gpu
#SBATCH --output=results/0851_genePlots_by_gggenomes/tmp/slurm/%j.out
#SBATCH --error=results/0851_genePlots_by_gggenomes/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0851_genePlots_by_gggenomes
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    data_directory=$( grep my_data_dir $parameters | awk '{print $2}' )
	panaroo_file=$( grep my_panaroo_file $parameters | awk '{print $2}' )

###############################################################################
	log "STARTED :SBATCH : $pipeline -----------------------------"
###############################################################################

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate genePlot_v0.0.1
	if [ -s "$panaroo_file" ]; then
		log "RUNNING: genePlot : with panaroo_file"
		bash /vast/xa73pav/projects/p_swapnil_genePlot/genePlot.sh \
		-d "$data_directory" \
		-o "$raw_files" \
		-c "$SLURM_CPUS_PER_TASK" \
		-p $panaroo_file

	else
		log "RUNNING: genePlot"
		bash /vast/xa73pav/projects/p_swapnil_genePlot/genePlot.sh \
		-d "$data_directory" \
		-o "$raw_files" \
		-c "$SLURM_CPUS_PER_TASK" 
	fi

###############################################################################
	log "ENDED :SBATCH : $pipeline -----------------------------"
############################################################################### 
