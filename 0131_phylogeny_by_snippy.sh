#!/bin/bash
############################################################################### 
## step-00: preparations
    pipeline=0131_phylogeny_by_snippy
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ----------------------------------"
##############################################################################
## step-01: creation and submission of jobs
    data_type=$(grep -w "my_data_type" $parameters | awk '{print $2}')

    echo "ID,CHROM,POS,TYPE,REF,ALT,EVIDENCE,FTYPE,STRAND,NT_POS,AA_POS,EFFECT,LOCUS_TAG,GENE,PRODUCT" > $wd/summary.csv

    create_directories_structure_1 $wd

    if [ $data_type == "paired" ]; then
        awk '/reverse_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/paired.txt
        list=$wd/tmp/paired.txt
        elif [ $data_type == "single" ]; then
        awk '/single_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/single.txt
        list=$wd/tmp/single.txt
    fi


    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
