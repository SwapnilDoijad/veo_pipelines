#!/bin/bash
###############################################################################
#SBATCH --job-name=0001_download_data_from_NCBI_by_dataset
#SBATCH --partition=standard
#SBATCH --output=data/ncbi_datasets/tmp/slurm/%j.out
#SBATCH --error=data/ncbi_datasets/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
############################################################################### 
	pipeline=0001_download_data_from_NCBI_by_dataset
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

  name=$(grep my_name $parameters | awk '{print $2}' | sed 's/_/ /g')
###############################################################################
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh \
    && conda activate ncbi_dataset_v17.0.0 

    log "Downloading genomes for all strains for $name : Will take a while"
    datasets download genome accession --inputfile data/ncbi_datasets/"$name"_all_strains.accessions.txt --filename  data/ncbi_datasets/multiple_genomes.zip

    log "Unzipping genomes for all strains for $name"
    unzip data/ncbi_datasets/multiple_genomes.zip -d data/ncbi_datasets/fasta

    for i in $(ls data/ncbi_datasets/fasta/ncbi_dataset/data ); do 
      cp data/ncbi_datasets/fasta/ncbi_dataset/data/$i/*.fna data/ncbi_datasets/fasta/$i.fasta
    done

    rm -rf data/ncbi_datasets/fasta/ncbi_dataset

###############################################################################