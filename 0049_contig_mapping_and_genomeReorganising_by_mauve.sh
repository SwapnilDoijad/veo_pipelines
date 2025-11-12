#!/bin/bash
###############################################################################
    pipeline=0049_contig_mapping_and_genomeReorganising_by_mauve
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    log "STARTED : $pipeline -----------------------------------------------------"
###############################################################################
    grep -v "#" $parameters | sed '/^$/d' > list.$pipeline.txt
    list=list.$pipeline.txt
    choise=$(grep -w "my_choise" $parameters | awk -F'\t' '{print $2}')

    create_directories_structure_1 $wd
    if [ $choise == "ordering" ]; then
        split_list $wd list.$pipeline.txt
        submit_jobs $wd $pipeline

        mkdir $wd/all_fasta
    elif [ $choise == "viewing" ]; then
        cp /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch \
        $wd/tmp/sbatch/

        sbatch $wd/tmp/sbatch/$pipeline.sbatch
    fi


###############################################################################
    log "ENDED : $pipeline ----------------------"
###############################################################################
