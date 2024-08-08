#!/bin/bash
#SBATCH --job-name '0051_metagenome_assembly_by_canu'
#SBATCH --partition=standard
#SBATCH --ntasks=1
#SBATCH --output  tmp/slurm/0000_veo_pipeline.%j.out.txt
#SBATCH --error   tmp/slurm/0000_veo_pipeline.%j.err.txt
#SBATCH --mail-type=END
#SBATCH --mail-user=xiu.jia@uni-jena.de 
#-- Command section ------------------------

/home/groups/VEO/scripts_for_users/0051_metagenome_assembly_by_canu.sh
