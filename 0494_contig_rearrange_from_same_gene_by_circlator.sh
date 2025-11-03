#!/bin/bash
###############################################################################
## header 
    pipeline=0494_contig_rearrange_from_same_gene_by_circlator
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"
###############################################################################
## step-01: preparation
    fasta_path=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    ls $fasta_path/ | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt
	start_gene_path=$( grep "start_gene" $parameters | awk '{print $2}' )
	start_gene_name=$( basename $start_gene_path | sed 's/\.fasta//g' )

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

	mkdir $wd/all_fasta_${start_gene_name}_rearranged_by_circlator
###############################################################################
## footer
    log "ENDED : $pipeline ----------------------" 
###############################################################################