#!/bin/bash
#SBATCH --job-name 0000_veo_pipeline
#SBATCH --partition=short,interactive,standard,long,gpu
#SBATCH --ntasks=1
#SBATCH --output tmp/slurm/%j.0000_veo_pipeline.out
#SBATCH --error tmp/slurm/%j.0000_veo_pipeline.err
#SBATCH --mail-type=END
#SBATCH --mail-user=your_email@example.com,swapnil.doijad@gmail.com
#-- Command section ------------------------

