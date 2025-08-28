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
  type_strains=$(grep my_type_strains $parameters | awk '{print $2}')

###############################################################################
## for Type Strains 

  if [ $type_strains == "Y" ]; then
    log "Downloading Type Strains for $name"

    datasets summary genome taxon "$name" --from-type --report genome > data/ncbi_datasets/"$name"_type_strains.json

    ## for all strains
      if [ ! -f data/ncbi_datasets/"$name"_type_strains.json ]; then
        datasets summary genome taxon "$name" --report genome \
        > data/ncbi_datasets/"$name"_type_strains.json
      fi
    
    ## parse the accession numbers from the JSON file, so that we can use these accession numbers to download the genomes
      if [ ! -f data/ncbi_datasets/"$name"_type_strain_accessions.txt ]; then
          jq -r '.reports[].accession' \
          data/ncbi_datasets/"$name"_type_strains.json \
          > data/ncbi_datasets/"$name"_type_strain_accessions.txt
      fi

    ## metadata: Json to Tsv
      if [ ! -f data/ncbi_datasets/"$name"_type_strains.metadata.tsv ]; then 
        jq -r '
        ["Accession", "Organism Name", "Strain", "Assembly Level", "Genome Size (bp)", "GC Content (%)", "Sequencing Tech", "BioSample Accession", "BioProject Accession", "Isolation Source", "Collection Date", "Geographic Location", "Host", "Type Material", "Submitter"],
        (.reports[] | 
        [
          .accession // "N/A", 
          .organism.organism_name // "N/A", 
          .organism.infraspecific_names.strain // "N/A", 
          .assembly_info.assembly_level // "N/A", 
          .assembly_stats.total_sequence_length // "N/A", 
          .assembly_stats.gc_percent // "N/A", 
          .assembly_info.sequencing_tech // "N/A", 
          .assembly_info.biosample.accession // "N/A",
          .assembly_info.bioproject_accession // "N/A",
          .assembly_info.biosample.isolation_source // "N/A",
          .assembly_info.biosample.collection_date // "N/A",
          .assembly_info.biosample.geo_loc_name // "N/A",
          .assembly_info.biosample.host // "N/A",
          (.assembly_info.biosample.attributes[]? | select(.name=="type-material") | .value) // "N/A",
          .assembly_info.submitter // "N/A"
        ]) | @tsv' data/ncbi_datasets/"$name"_type_strains.json | tr ' ' '_' > data/ncbi_datasets/"$name"_type_strains.metadata.tsv
      fi

    ## ONLY FOR TYPE STRAIN: remove duplicates: sometimes genomes are duplicated, remove duplicate genomes
      if [ ! -f data/"$name"_type_strains.metadata.txt ] ; then 
        log "Removing duplicate genomes from metadata file"
        awk -F'\t' 'NR>1 && !seen[$2]++ { print $1}' data/ncbi_datasets/"$name"_type_strains.metadata.tsv > data/"$name"_type_strains.accessions.txt
        awk -F'\t' '!seen[$2]++ { print $0}' data/ncbi_datasets/"$name"_type_strains.metadata.tsv > data/"$name"_type_strains.metadata.txt
      fi

    datasets download genome accession --inputfile data/"$name"_type_strains.accessions.txt --filename  data/ncbi_datasets/multiple_genomes.zip
    unzip data/ncbi_datasets/multiple_genomes.zip -d data/ncbi_datasets/fasta

      for i in $(ls data/ncbi_datasets/fasta/ncbi_dataset/data ); do 
        cp data/ncbi_datasets/fasta/ncbi_dataset/data/$i/*.fna data/ncbi_datasets/fasta/$i.fasta
      done
      rm -rf data/ncbi_datasets/fasta/ncbi_dataset

    exit
  fi
###############################################################################
## All strains

    log "Getting metadata for all strains for $name"

    ## for all strains
      if [ ! -f data/ncbi_datasets/"$name"_all_strains.json ]; then
        datasets summary genome taxon "$name" --report genome \
        > data/ncbi_datasets/"$name"_all_strains.json
      fi
    
    ## parse the accession numbers from the JSON file, so that we can use these accession numbers to download the genomes
      if [ ! -f data/ncbi_datasets/"$name"_type_strain_accessions.txt ]; then
          jq -r '.reports[].accession' \
          data/ncbi_datasets/"$name"_all_strains.json \
          > data/ncbi_datasets/"$name"_type_strain_accessions.txt
      fi

    ## metadata: Json to Tsv
      if [ ! -f data/ncbi_datasets/"$name"_all_strains.accessions.txt ]; then 
        jq -r '
        ["Accession", "Organism Name", "Strain", "Assembly Level", "Genome Size (bp)", "GC Content (%)", "Sequencing Tech", "BioSample Accession", "BioProject Accession", "Isolation Source", "Collection Date", "Geographic Location", "Host", "Type Material", "Submitter"],
        (.reports[] | 
        [
          .accession // "N/A", 
          .organism.organism_name // "N/A", 
          .organism.infraspecific_names.strain // "N/A", 
          .assembly_info.assembly_level // "N/A", 
          .assembly_stats.total_sequence_length // "N/A", 
          .assembly_stats.gc_percent // "N/A", 
          .assembly_info.sequencing_tech // "N/A", 
          .assembly_info.biosample.accession // "N/A",
          .assembly_info.bioproject_accession // "N/A",
          .assembly_info.biosample.isolation_source // "N/A",
          .assembly_info.biosample.collection_date // "N/A",
          .assembly_info.biosample.geo_loc_name // "N/A",
          .assembly_info.biosample.host // "N/A",
          (.assembly_info.biosample.attributes[]? | select(.name=="type-material") | .value) // "N/A",
          .assembly_info.submitter // "N/A"
        ]) | @tsv' data/ncbi_datasets/"$name"_all_strains.json | tr ' ' '_' \
        > data/ncbi_datasets/"$name"_all_strains.metadata.tsv.tmp

        ## remove GCF_ and GCA_ versions of the same genome
          awk '
          {
              if ($1 ~ /^GC[FA]_/) {
                  num = substr($1, 5)
              }

              if ($1 ~ /^GCF_/) {
                  has_gcf[num] = 1
              }
              
              # Store all lines keyed by their numeric part
              lines[num][$1] = $0
          }
          END {
              for (num in lines) {
                  if (has_gcf[num]) {
                      print lines[num]["GCF_" num]
                  } 
                  else {
                      for (prefix in lines[num]) {
                          print lines[num][prefix]
                      }
                  }
              }
          }' data/ncbi_datasets/"$name"_all_strains.metadata.tsv.tmp \
          > data/ncbi_datasets/"$name"_all_strains.metadata.tsv

          # rm data/ncbi_datasets/"$name"_all_strains.metadata.tsv.tmp

        awk -F'\t' 'NR>1 { print $1}' data/ncbi_datasets/"$name"_all_strains.metadata.tsv \
        | grep -v "Accession" \
        > data/ncbi_datasets/"$name"_all_strains.accessions.txt
      fi

    log "SUBMITTING SBATCH: $name"
    sbatch $suppl_scripts/0001_download_data_from_NCBI_by_dataset.sbatch > /dev/null 2>&1

###############################################################################
  log "ENDED: $pipeline"
###############################################################################