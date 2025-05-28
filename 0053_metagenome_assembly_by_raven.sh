#!/bin/bash
###############################################################################
echo "script 0053_metagenome_assembly_by_raven started ---------------------------------"
###############################################################################
## step-00: preparation
	pipeline=0053_metagenome_assembly_by_raven
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
	ls $fastq_path/ | sed 's/\.fastq\.gz//g' > list.$pipeline.txt
	list=list.$pipeline.txt

	(mkdir -p results/0053_metagenome_assembly_by_raven/all_fasta ) > /dev/null 2>&1

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
# ## step-01: raven assembly
# 	if [ ! -f results/0053_metagenome_assembly_by_raven/tmp/raven_assembly.finished ] ; then
# 		for sublist in $( ls results/0053_metagenome_assembly_by_raven/tmp/lists/ ) ; do
# 			echo "batch $sublist for raven assembly: creating" 
			
# 			sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0053_metagenome_assembly_by_raven.sbatch \
# 			| sed "s#XYZ#$fastq_path#g" \
# 			> results/0053_metagenome_assembly_by_raven/tmp/sbatch/0053_metagenome_assembly_by_raven.$sublist.sbatch

# 			sbatch results/0053_metagenome_assembly_by_raven/tmp/sbatch/0053_metagenome_assembly_by_raven.$sublist.sbatch

# 			echo "batch $sublist for raven assembly: submitted" 
# 		done
# 		echo "step-01: raven assembly finished" > results/0053_metagenome_assembly_by_raven/tmp/raven_assembly.finished
# 	fi
# ###############################################################################
# ## step-02: wait untill assembly is finished
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

# ###############################################################################
# ## step-03: run metaquast
# 	echo "running metaquast "
#     for F1 in $(cat $list); do  
# 		if [ -f results/0053_metagenome_assembly_by_raven/raw_files/$F1/$F1.fasta ] ; then 
# 			if [ ! -d results/0053_metagenome_assembly_by_raven/raw_files/$F1/metaquast/fasta ] ; then 
# 				echo "metaquast for $F1: running"
# 				mkdir -p results/0053_metagenome_assembly_by_raven/raw_files/$F1/metaquast/fasta
# 				cp results/0053_metagenome_assembly_by_raven/raw_files/$F1/$F1.fasta \
# 				results/0053_metagenome_assembly_by_raven/raw_files/$F1/metaquast/fasta/

# 				cp results/0053_metagenome_assembly_by_raven/raw_files/$F1/$F1.fasta \
# 				results/0053_metagenome_assembly_by_raven/all_fasta/$F1.fasta

# 				( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
# 				-o results/0053_metagenome_assembly_by_raven/raw_files/$F1/metaquast/ \
# 				results/0053_metagenome_assembly_by_raven/raw_files/$F1/metaquast/fasta/*  ) > /dev/null 2>&1
# 				else
# 				echo "metaquast for $F1: already finished" 
# 			fi 
# 		fi
#     done 

# 	for F1 in $(cat $list); do  
# 		if [ -f results/0053_metagenome_assembly_by_raven/raw_files/$F1/$F1.fasta ] ; then 
# 			awk -F'\t' '{print $2}' results/0053_metagenome_assembly_by_raven/raw_files/$F1/metaquast/report.tsv | sed "s/assembly/$F1/g" \
# 			> results/0053_metagenome_assembly_by_raven/tmp/$F1.metaquast.txt 
# 			else
# 			echo $F1 > results/0053_metagenome_assembly_by_raven/tmp/$F1.metaquast.txt 
# 			for i in {1..22}; do echo "na" >> results/0053_metagenome_assembly_by_raven/tmp/$F1.metaquast.txt ; done
# 		fi 
# 	done 
# 	sleep 10
	
# 	paste \
# 	results/0053_metagenome_assembly_by_raven/tmp/*.metaquast.txt \
# 	> results/0053_metagenome_assembly_by_raven/summary.tsv

# 	cat /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt \
# 	results/0053_metagenome_assembly_by_raven/summary.tsv \
# 	> results/0053_metagenome_assembly_by_raven/summary.2.tsv

# ###############################################################################
# ## step-04: split mulitfasta to single fasta
# 	( mkdir data/all_fasta_splitted )> /dev/null 2>&1
# 	for i in $(cat list.my_fasta.txt ); do
# 		echo "STARTED: splitting and renaming $i"
# 		( rm -rf results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1 )> /dev/null 2>&1
# 		echo $i
# 		/home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_fasta.pl \
# 		--input_file=results/0052_metagenome_assembly_by_fly/all_fasta/$i.fasta \
# 		--output_dir=results/0052_metagenome_assembly_by_fly/raw_files/$i \
# 		--output_subdir_prefix=all_fasta_splitted_ \
# 		--output_subdir_size 10000 
# 		for i2 in $( ls results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/ ); do 
# 			mv results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/$i2 \
# 			results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/"$i"_"$i2"
# 			sed -i "s/>/>"$i"_/g" results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/"$i"_"$i2"
# 		done 
# 		cp results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/*.fasta \
# 		data/all_fasta_splitted/
# 	done  
# ###############################################################################
# ## step-05: send report by email (with attachment)

#     echo "sending email"
#     user=$(whoami)
#     user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

#     source /home/groups/VEO/tools/email/myenv/bin/activate

#     python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0053_metagenome_assembly_by_raven.py -e $user_email

#     deactivate
###############################################################################
echo "script 0053_metagenome_assembly_by_raven ended --------------------------------------"
###############################################################################

