#!/bin/bash
###############################################################################
## header
	pipeline=0054_metagenome_assembly_by_metaspades_for_illumina
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : $pipeline started ------------------------------------"
###############################################################################
## step-01: preparation

	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
	ls $fastq_path/ | sed 's/\.fastq\.gz//g' > list.fastq.$pipeline.txt
	list=list.fastq.$pipeline.txt

	echo -e "IDs\tnumber_of_contigs" > $summary.tsv

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
	# ## step-02: wait untill assembly is finished
	# 	rm $wd/tmp/metaspades_assembly.finished > /dev/null 2>&1
	# 	if [ ! -f $wd/tmp/metaspades_assembly.finished ] ; then 
	# 		counter=0
	# 		max_attempts=1800 ## 30 hours

	# 		cat $list > $wd/tmp/tmp.list
	# 		while [ $counter -lt $max_attempts ] && [ -s $wd/tmp/tmp.list ]; do
	# 			for F1 in $(cat $wd/tmp/tmp.list); do
	# 				if [ -f "$wd/raw_files/$F1/contigs.fasta" ] || grep -q "== Error ==" $wd/raw_files/$F1/spades.log ; then
	# 					sed -i "/$F1/d" $wd/tmp/tmp.list
	# 					echo "metaspades assembly $F1 finished, no more waiting"
	# 					break
	# 					else
	# 					echo "metaspades assembly $F1 not finished in $counter/$max_attempts minutes, waiting another minute"
	# 					sleep 60
	# 					counter=$((counter + 1))
	# 				fi
	# 			done
	# 		done

	# 		if [ $counter -eq $max_attempts ]; then
	# 			echo "File not found after 30 hour. Exiting..."
	# 		fi

	# 		rm $wd/tmp/tmp.list > /dev/null 2>&1
	# 		sleep 60 ## needed for the files to be writen, it takes time for the metaspades 
	# 		echo "metaspades assembly finished" > $wd/tmp/metaspades_assembly.finished
	# 	fi 
	
###############################################################################
## step-02: run metaquast
	# echo "running metaquast "
    # for F1 in $(cat $list); do  
	# 	if [ -f $wd/raw_files/$F1/$F1.contigs.fasta ] ; then 
	# 		if [ ! -d $wd/raw_files/$F1/quast/fasta ] ; then 
	# 			echo "metaquast for $F1: running"
	# 			mkdir -p $wd/raw_files/$F1/quast/fasta
	# 			cp $wd/raw_files/$F1/$F1.contigs.fasta $wd/raw_files/$F1/quast/fasta/

	# 			cp results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta \
	# 			results/0052_metagenome_assembly_by_fly/all_fasta/$F1.fasta

	# 			python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
	# 			-o $wd/raw_files/$F1/quast/ \
	# 			$wd/raw_files/$F1/quast/fasta/* 
	# 			else
	# 			echo "metaquast for $F1: already finished"
	# 		fi
	# 	fi
    # done 

	# for F1 in $(cat $list); do  
	# 	if [ -f $wd/raw_files/$F1/$F1.contigs.fasta ] ; then 
	# 		awk -F'\t' '{print $2}' $wd/raw_files/$F1/quast/report.tsv \
	# 		> $wd/tmp/$F1.metaquast.txt 
	# 		else
	# 		echo $F1.contigs > $wd/tmp/$F1.metaquast.txt 
	# 		for i in {1..22}; do echo "na" >> $wd/tmp/$F1.metaquast.txt ; done
	# 	fi 
	# done 
	# paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt $wd/tmp/*.metaquast.txt \
	# > $wd/summary.tsv
###############################################################################
## step-03: send report by email (with attachment)

    # echo "sending email"
    # user=$(whoami)
    # user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    # source /home/groups/VEO/tools/email/myenv/bin/activate

    # python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/$pipeline.py -e $user_email

    # deactivate
###############################################################################
	log "ENDED : $pipeline ended --------------------------------------"
###############################################################################


