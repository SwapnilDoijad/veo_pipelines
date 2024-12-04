#!/bin/bash
#SBATCH --job-name 0641_vibrant
#SBATCH --partition=long
#SBATCH --output slurm.out.%j
#SBATCH --error  slurm.err.%j
#SBATCH --ntasks=1
#-- Command section ------------------------

bash /home/groups/VEO/scripts_for_users/supplementary_scripts/0641_vibrant.sh
