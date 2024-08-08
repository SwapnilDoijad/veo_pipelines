#!/bin/bash
###############################################################################
## header
    pipeline=0065_read_mapping_by_minimap2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ----------------------------------"
##############################################################################
## step-01: preparations
    # parameter_file=tmp/parameters/$pipeline.yaml
    grep -v "#" tmp/parameters/$pipeline.txt > tmp/parameters/list.$pipeline.txt
    list=tmp/parameters/list.$pipeline.txt

    (rm $wd/tmp/slurm/*.$pipeline.txt ) > /dev/null 2>&1
    (rm $wd/tmp/sbatch/$pipeline.*.sbatch ) > /dev/null 2>&1
    (rm $wd/summary.txt ) > /dev/null 2>&1

    create_directories_structure_1 $wd
    split_list $wd $list

    (mkdir -p $raw_files/index_files ) > /dev/null 2>&1
    (mkdir -p $raw_files/sam_files ) > /dev/null 2>&1
    (mkdir -p $raw_files/sam_files_sorted ) > /dev/null 2>&1
    (mkdir -p $raw_files/depth_and_coverage ) > /dev/null 2>&1
###############################################################################
## create and submit sbatch

    for sublist in $( ls $wd/tmp/lists/ ); do 
        echo "creating sbatch for $sublist, and submitting"
        sed "s/ABC/$sublist/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch \
        > $wd/tmp/sbatch/$pipeline.$sublist.sbatch
        sbatch $wd/tmp/sbatch/$pipeline.$sublist.sbatch
    done

    number_of_sublist=$(ls $wd/tmp/lists/ | wc -l)
    while [ "$number_of_sublist" != "$number_of_sublist_finished" ]; do
        sleep 300
        number_of_sublist_finished=$( grep -c "The run for sublist :" $wd/tmp/slurm/*.out.$pipeline.txt  | wc -l )
        echo "$number_of_sublist_finished/$number_of_sublist finished by now, waiting for 5 min" 
    done 

###############################################################################
## step-03: send report by email (with attachment)

    # echo "sending email"
    # user=$(whoami)
    # user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    # source /home/groups/VEO/tools/email/myenv/bin/activate

    # python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0065_metagenome_assembly_by_raven.py -e $user_email

    deactivate

###############################################################################
## footer
    log "ENDED : $pipeline ----------------------------------"
###############################################################################