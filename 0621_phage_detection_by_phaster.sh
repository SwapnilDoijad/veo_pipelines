#!/bin/bash
###############################################################################
## header 
	pipeline=0621_phage_detection_by_phaster
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
###############################################################################
## step-00: preparation	
    fasta_dir=$(grep "my_fasta_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
    ls $fasta_dir/ | sed 's/.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    # split_list $wd $list
    # submit_jobs $wd $pipeline
###############################################################################
for file in $(cat $list); do
    if [ ! -d $raw_files/$file ] ; then 
        log "uploading $file.fasta"
        (mkdir $raw_files/$file) > /dev/null 2>&1
        wget -q --post-file="$fasta_dir/$file.fasta" "http://phaster.ca/phaster_api?contigs=1" -O $raw_files/$file/$file.txt
    fi
done
###############################################################################
for file in $(cat $list); do
    if [ -d $raw_files/$file ] ; then 
        log "getting status for $file"
        link=$(cat $raw_files/$file/$file.txt | awk -F'"' '{print $4}')
        wget -q "http://phaster.ca/phaster_api?acc=$link" -O $raw_files/$file/$file.txt
    fi
done
##############################################################################