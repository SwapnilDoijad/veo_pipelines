#!/bin/bash
###############################################################################
  pipeline=0001_download_data_from_NCBI_by_dataset
  source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
  log "STARTED: $pipeline"
###############################################################################
  source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh \
  && conda activate ncbi_dataset_v17.0.0 

  mkdir -p data/ncbi_datasets/fasta
  name=$(grep my_name $parameters | awk '{print $2}'| sed 's/_/ /g')
  name2=$(grep my_name $parameters | awk '{print $2}')
  type_strains=$(grep my_type_strains $parameters | awk '{print $2}')

###############################################################################

    log "SUBMITTING SBATCH: $name2"
    sbatch $suppl_scripts/0001_download_data_from_NCBI_by_dataset.sbatch > /dev/null 2>&1

###############################################################################
  log "ENDED: $pipeline"
###############################################################################