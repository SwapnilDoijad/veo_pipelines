#!/bin/bash
#SBATCH --job-name 0006_pod5
#SBATCH --partition=long
#SBATCH --output tmp/slurm/slurm.out.%j
#SBATCH --error  tmp/slurm/slurm.err.%j
#SBATCH --ntasks=1
#-- Command section ------------------------

source /home/groups/VEO/tools/pod5/v0.2.2/bin/activate

