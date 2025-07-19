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
    jaeger_version=$(grep "my_jaeger_version" $parameters | awk '{print $2}')
    
    create_directories_structure_1 $wd
    split_list $wd $list
    mkdir -p $raw_files/phage
    mkdir -p $raw_files/prophage
    # submit_jobs $wd $pipeline
    # sbatch $suppl_scripts/$pipeline.sbatch

    for sublist in $(ls "$wd"/tmp/lists/); do
        echo "sublist: $sublist"
        if [ $jaeger_version == "v1.2" ]; then
                sed "s|ABC|$sublist|g" $suppl_scripts/$pipeline.v1.2.sbatch \
                > "$wd"/tmp/sbatch/"$pipeline.$sublist.v1.2.sbatch"
                sbatch "$wd"/tmp/sbatch/"$pipeline.$sublist.v1.2.sbatch"
            elif [ $jaeger_version == "v1.1" ]; then
                sed "s|ABC|$sublist|g" $suppl_scripts/$pipeline.v1.1.sbatch \
                > "$wd"/tmp/sbatch/"$pipeline.$sublist.v1.1.sbatch"
                sbatch "$wd"/tmp/sbatch/"$pipeline.$sublist.v1.1.sbatch"
            else
                echo "Please check the Jaeger version in the parameter file: $parameters"
        fi
    done 

    echo -e "ids\tnumber_of_phages\tnumber_of_prophages" > $wd/phage_prophage_count.tsv
###############################################################################
    echo "ENDED : $pipeline ----------------------------"
###############################################################################
