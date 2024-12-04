#!/bin/bash
#SBATCH --job-name=m004_otu2matrix
#SBATCH --partition=interactive
#SBATCH --output=results/m004_otu2matrix/tmp/slurm/%j.out
#SBATCH --error=results/m004_otu2matrix/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################
## step-00: preparation
	pipeline=m004_otu2matrix
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
###############################################################################
    log "STARTED SBATCH: $pipeline --------------------"
###############################################################################

	source /home/groups/VEO/tools/biopython/myenv/bin/activate

	python /home/groups/VEO/scripts_for_users/supplementary_scripts/m004_otus2matrix.py \
	-i $sublist -o $raw_files/ABC.tsv

	deactivate

###############################################################################
    log "FINISHED SBATCH: $pipeline --------------------"
###############################################################################