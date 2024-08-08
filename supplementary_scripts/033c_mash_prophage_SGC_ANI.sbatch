#!/bin/bash
#SBATCH --job-name 033c_mash_prophage_SGC_ANI
#SBATCH --partition=long
#SBATCH --output slurm.out.%j
#SBATCH --error  slurm.err.%j
#SBATCH --ntasks=1
#-- Command section ------------------------

/home/groups/VEO/scripts_for_users/supplementary_scripts/033c_mash_prophage_SGC_ANI.sh
