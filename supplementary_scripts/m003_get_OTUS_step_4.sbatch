#!/bin/bash
#SBATCH --job-name m003_get_OTUs_step-4
#SBATCH --partition=long
#SBATCH --output tmp/step_4/slurm_out/m003_get_OTUs_step-4.out.%j
#SBATCH --error  tmp/step_4/slurm_out/m003_get_OTUs_step-4.err.%j
#SBATCH --ntasks=1
#-- Command section ------------------------

/home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUS_step_4.sh
