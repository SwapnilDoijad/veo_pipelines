#!/bin/bash
#SBATCH --job-name 0000_veo_pipeline
#SBATCH --partition=long
#SBATCH --ntasks=1
#SBATCH --output  tmp/slurm/%j.out.0000_veo_pipeline.txt
#SBATCH --error   tmp/slurm/%j.err.0000_veo_pipeline.txt
#-- Command section ------------------------

