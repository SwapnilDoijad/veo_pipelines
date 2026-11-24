#!/bin/bash
###############################################################################
## header
    pipeline=0801_mcfDNA_analysis_by_banz
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
    data_directory=$( grep my_data_dir $parameters | awk '{print $2}' )
    ls $data_directory | sed 's/\.fastq.gz$//' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

    # cp $suppl_scripts/${pipeline}.sbatch $wd/tmp/sbatch/${pipeline}.sbatch
    # sbatch $wd/tmp/sbatch/${pipeline}.sbatch

    # if [[ ! -f "$wd/reads.tsv" ]] ; then
    #     echo -e "ID\tReads" > $wd/reads.tsv
        # printf 'sample\ttotal\tge35\tge50\tge100\tge250\n' > ${wd}/reads_length_distribution.tsv
        echo -e "Genus\tKraken_Assigned_Reads\treads_mapped_to_genus\tSpecies\treads_mapped_to_species" > ${wd}/summary.tsv
    # fi
###############################################################################
    echo "FINISHED : $pipeline ---------------------------------"
###############################################################################