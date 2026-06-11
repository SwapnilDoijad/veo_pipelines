#!/bin/bash
###############################################################################
## header
    pipeline=0660_phage_taxonomy_by_vcat
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    basename -a $fasta_directory/*.fasta | sed 's/\.fasta$//' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    # submit_jobs $wd $pipeline
    ## snakemake pipeline, don't parallalelise
    cp ${suppl_scripts}/${pipeline}.sbatch \
    $wd/tmp/sbatch/
    sbatch $wd/tmp/sbatch/${pipeline}.sbatch

    echo -e "ID\tSequenceID\tSeqlen\tScore\tMethod\tRealm (-viria)\tRealm_score\tSubrealm (-vira)\tSubrealm_score\tKingdom (-virae)\tKingdom_score\tSubkingdom (-virites)\tSubkingdom_score\tPhylum (-viricota)\tPhylum_score\tSubphylum (-viricotina)\tSubphylum_score\tClass (-viricetes)\tClass_score\tSubclass (-viricetidae)\tSubclass_score\tOrder (-virales)\tOrder_score\tSuborder (-virineae)\tSuborder_score\tFamily (-viridae)\tFamily_score\tSubfamily (-virinae)\tSubfamily_score\tGenus (-virus)\tGenus_score\tSubgenus (-virus)\tSubgenus_score\tSpecies (binomial)\tSpecies_score" \
    > ${wd}/summary.csv
###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################