###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0067_identification_contigs_by_CAT -------------------------"
###############################################################################
## step-01: file and directory preparation
    pipeline=0067_identification_contigs_by_CAT_BAT_RAT
    wd=results/$pipeline

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################

# ## step-03: wait untill assembly is finished
# 	if [ ! -f results/0053_metagenome_assembly_by_raven/tmp/get_the_stat_of_fasta_finished.txt ] ; then 
# 		counter=0
# 		max_attempts=180  # 60 attempts * 1 minute = 1 hour

# 		cat $list > results/0053_metagenome_assembly_by_raven/tmp/tmp.list

# 		while [ $counter -lt $max_attempts ]  && [ -s results/0053_metagenome_assembly_by_raven/tmp/tmp.list ] ; do
# 			for F1 in $(cat results/0053_metagenome_assembly_by_raven/tmp/tmp.list); do
# 				if [ -f "results/0053_metagenome_assembly_by_raven/raw_files/$F1/$F1.fasta" ]; then
# 					sed -i "/$F1/d" results/0053_metagenome_assembly_by_raven/tmp/tmp.list
# 					echo "raven assembly $F1 finished, no more waiting"
# 					break
# 					else
# 					echo "raven assembly $F1 not finished in $counter minutes"
# 					echo "waiting for 1 more minute and will check again (will wait maximum $max_attempts minutes)"
# 					sleep 60
# 					counter=$((counter + 1))
# 				fi
# 			done
# 		done

# 		if [ $counter -eq $max_attempts ]; then
# 			echo "File not found after 3 hour. Exiting..."
# 		fi

# 		rm results/0053_metagenome_assembly_by_raven/tmp/tmp.list
# 		sleep 60 ## needed for the files to be writen, it takes time for the raven 
# 		echo "raven assembly finished" > results/0053_metagenome_assembly_by_raven/tmp/raven_assembly.finished
# 	fi 

###############################################################################
## footer
    log "ENDED : 0067_identification_contigs_by_CAT -------------------------"
###############################################################################