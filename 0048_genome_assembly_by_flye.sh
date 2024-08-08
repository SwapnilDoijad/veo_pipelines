#!/bin/bash
###############################################################################
## header 

    pipeline=0048_genome_assembly_by_flye
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"

###############################################################################
## step-01: preparation
    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
#######################################################################
## footer
    log "ENDED : $pipeline ----------------------"
###############################################################################

## step-02: wait untill assembly is finished
	# if [ -f $wd/tmp/flye_assembly.finished ] ; then 
	# 	counter=0
	# 	max_attempts=180  # 60 attempts * 1 minute = 1 hour

	# 	cat $list > $wd/tmp/tmp.list

	# 	while [ $counter -lt $max_attempts ] && [ -s $wd/tmp/tmp.list ] ; do
	# 		for F1 in $(cat $wd/tmp/tmp.list); do
	# 			if [ -e "results/$pipeline/raw_files/$F1/assembly.fasta" ] || grep -q "ERROR: Pipeline aborted" $wd/raw_files/$F1/flye.log ; then
	# 				sed -i "/$F1/d" $wd/tmp/tmp.list
	# 				log "FINISHED : assembly by flye for $F1"
	# 				break
	# 				else
	# 				log "WAITING : assembly by flye for $F1 (not finished in $counter / $max_attempts minutes)"
	# 				sleep 60
	# 				counter=$((counter + 1))
	# 			fi

	# 			if [ $counter -eq $max_attempts ]; then
	# 				log "ERROR : assembly for $F1 not finished in 3 hours. Assembly failed? exiting..."
	# 			fi

	# 		done
	# 	done

	# 	# rm $wd/tmp/tmp.list
	# 	sleep 60 ## needed for the files to be writen
	# 	echo "flye assembly finished" > $wd/tmp/flye_assembly.finished
	# fi 
###############################################################################
## step-03: send report by email (with attachment)

    # echo "sending email"
    # user=$(whoami)
    # user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    # source /home/groups/VEO/tools/email/myenv/bin/activate

    # python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/$pipeline.py -e $user_email

    # deactivate
###############################################################################
## footer
	log "ENDED : $pipeline --------------------------------------------"
##############################################################################
