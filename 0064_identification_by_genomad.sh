###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0064_identification_by_genomad ------------------------------"
###############################################################################
## step-01: preparations
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0064_identification_by_genomad
    wd=results/$pipeline
    send_email=send_email_answer

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        elif [ -f list.bacterial_fasta.txt ]; then
        list=list.bacterial_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep fasta result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

exit
###############################################################################
## step-03: wait untill assembly is finished

		counter=0
		max_attempts=180  # 60 attempts * 1 minute = 1 hour

		cat $list > $wd/tmp/tmp.list

		while [ $counter -lt $max_attempts ] && [ -s $wd/tmp/tmp.list ] ; do
			for F1 in $(cat $wd/tmp/tmp.list ); do
				if [ -f "$wd/raw_files/$F1/"$F1"_summary.log" ]; then
					sed -i "/$F1/d" $wd/tmp/tmp.list
					log "FINISHED : 0064_identification_by_genomad $F1 finished, no more waiting"
					break
					else
					log "WAITING : 0064_identification_by_genomad $F1 ($counter/$max_attempts elapsed), waiting for 1 more minute "
					sleep 60
					counter=$((counter + 1))
				fi
			done
		done

		if [ $counter -eq $max_attempts ]; then
			log "ERROR : File not found after 3 hour. Exiting..."
		fi

		rm $wd/tmp/tmp.list
		sleep 10 ## needed for the files to be writen, it takes time for the *_summary.log 

###############################################################################
## step-04: summarise the results
    echo "id	seq_name	length	topology	coordinates	n_genes	genetic_code	virus_score	fdr	n_hallmarks	marker_enrichment	taxonomy" > $wd/summary.tsv
    echo -e "sample_id\tnumber_of_phages_classified\tsummary_file" > $wd/results.0064_identification_by_genomad.tsv
    for i in $(cat $list); do 
        number_of_phages_identified=$( awk 'NR>1' $wd/raw_files/$i/"$i"_summary/"$i"_virus_summary.tsv | wc -l )
        echo -e "$i\t$number_of_phages_identified\t$wd/raw_files/$i/"$i"_summary/"$i"_virus_summary.tsv"  >> $wd/results.0064_identification_by_genomad.tsv
        awk 'NR>1' $wd/raw_files/$i/"$i"_summary/"$i"_virus_summary.tsv | sed -e 's/^/'"$i\t"'/g' >> $wd/summary.tsv
    done  

###############################################################################
## step-05: send report by email (with attachment)
    if [ $send_email == "yes" ]; then

        user=$(whoami)
        user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

        source /home/groups/VEO/tools/email/myenv/bin/activate

        python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0064_identification_by_genomad.py -e $user_email
        log "SENT : email"
        deactivate
    fi
###############################################################################
## footer
    log "ENDED : 0064_identification_by_genomad ------------------------------"
###############################################################################
