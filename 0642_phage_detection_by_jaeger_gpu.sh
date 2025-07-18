#!/bin/bash
###############################################################################
## header
    pipeline=0642_phage_detection_by_jaeger_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline --------------------------"
###############################################################################
## step-01: preparations

    fasta_path=$(grep "fasta_path" $parameters | awk '{print $2}')
    ls $fasta_path/ | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt
    
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
    # sbatch $suppl_scripts/$pipeline.sbatch

    mkdir -p $raw_files/phage
    # mkdir -p $raw_files/prophage
    
    echo -e "ids\tnumber_of_phages\tnumber_of_prophages" > $wd/phage_prophage_count.tsv
###############################################################################
    echo "ENDED : $pipeline ----------------------------"
###############################################################################
