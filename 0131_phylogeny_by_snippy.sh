#!/bin/bash
############################################################################### 
## step-00: preparations
    pipeline=0131_phylogeny_by_snippy
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ----------------------------------"
##############################################################################
## step-01: creation and submission of jobs
    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		read l
		list=$(echo "list.$l.txt")
	fi

    echo "ID,CHROM,POS,TYPE,REF,ALT,EVIDENCE,FTYPE,STRAND,NT_POS,AA_POS,EFFECT,LOCUS_TAG,GENE,PRODUCT" > $wd/summary.csv

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
