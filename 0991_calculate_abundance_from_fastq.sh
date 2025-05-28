#!/bin/bash
###############################################################################
## header
    pipeline=0991_calculate_abundance_from_fastq
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline --------------------------------------"
###############################################################################
## preparation
    ## 2024-12-14 10:58:21  @Swapnil 
    ## there are too many reads longer than 1.5Kb and it has more than one primer !!!
    ## Nanopore is still shity !!!
    ## Next time
        ## 1: improvement: Cut the reads for 16S rRNA gene region (based on the primers)

        ## 2: Need to change below to avoid duplicates due to Nanopore-Read-Merge-Issue
        ## $raw_files/read_ids_extracted_per_sample/$sample_id.$subsample.tsv
        ## seperate fastq from $raw_files/read_ids_extracted_per_sample/$sample_id.$subsample.tsv 
        ## and henceforth run loop  for sample_id in $(cat $bp/list.samples.txt); do rather than while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do for simplifications 

        ## 3: try with 16S database only

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_calculate_abundance_from_fastq.sbatch
    
    echo "ENDED : $pipeline --------------------------------------"
###############################################################################