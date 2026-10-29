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
    if [ ! -f $raw_files/$file/$file.txt ] ; then 
        log "uploading $file.fasta"
        (mkdir $raw_files/$file) > /dev/null 2>&1
		wget -q --post-file="${fasta_dir}/${file}.fasta" "https://phastest.ca/phastest_api" -O $raw_files/$file/$file.txt
    fi
done
###############################################################################
for file in $(cat $list); do
    if [ ! -f $raw_files/$file/finished.txt ] ; then 
        log "getting status for $file"
        link=$(cat $raw_files/$file/$file.txt | awk -F'"' '{print $4}')
        while true; do
            wget -q "https://phastest.ca/phastest_api?acc=$link" -O $raw_files/$file/status.$file.txt
            if grep -q '"status":"Complete"' $raw_files/$file/status.$file.txt; then
                log "$file is complete" | tee -a $raw_files/$file/finished.txt
                break
            fi
            log "$file not complete yet, waiting 2 min"
            sleep 120
        done
    fi
done
##############################################################################
for file in $(cat $list); do
    link=$(awk -F'"' '{print $4}' $raw_files/$file/$file.txt)
    if [ ! -f $raw_files/$file/$file.zip ] ; then 
        log "downloading submission for $file"
        wget -O $raw_files/$file/$file.zip "https://phastest.ca/submissions/$link.zip"
        
        mkdir -p $raw_files/$file/results
        unzip $raw_files/$file/$file.zip -d $raw_files/$file/results

    fi
done
##############################################################################
