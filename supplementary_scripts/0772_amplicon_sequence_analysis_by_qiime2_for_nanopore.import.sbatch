#!/bin/bash
#SBATCH --job-name qiime2_import
#SBATCH --partition=short 
#SBATCH --output=results/0772_amplicon_sequence_analysis_by_qiime2_for_nanopore/tmp/slurm/out.%j.qiime2_import
#SBATCH --error=results/0772_amplicon_sequence_analysis_by_qiime2_for_nanopore/tmp/slurm/err.%j.qiime2_import
#-- Command section ------------------------

pipeline=0772_amplicon_sequence_analysis_by_qiime2_for_nanopore
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate qiime2-2023.5

file=my_file
sample_id=my_sample_id

	qiime tools import \
		--type 'FeatureData[Sequence]' \
		--input-path "$file" \
		--output-path $raw_files/qza/"${sample_id}.qza"