#!/bin/bash
###############################################################################
echo "script 0052_metagenome_assembly_by_fly started ---------------------------------"
###############################################################################
## step-00: preparation

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		read l
		list=$(echo "list.$l.txt")
	fi

	if [ -f result_summary.read_me.txt ]; then
        fastq_file_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fastq_file_path"
        read fastq_file_path
    fi

	(mkdir -p results/0052_metagenome_assembly_by_fly/all_fasta ) > /dev/null 2>&1
    (mkdir -p results/0052_metagenome_assembly_by_fly/raw_files ) > /dev/null 2>&1
	(mkdir -p results/0052_metagenome_assembly_by_fly/tmp/lists ) > /dev/null 2>&1
	(mkdir -p results/0052_metagenome_assembly_by_fly/tmp/sbatch ) > /dev/null 2>&1

    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 3 ))
    split -l "$lines_per_part" "$list" list.0052.fastq_
    mv list.0052.fastq_* results/0052_metagenome_assembly_by_fly/tmp/lists/

###############################################################################
## step-01: fly assembly
	## for re-running 
	## rm results/0052_metagenome_assembly_by_fly/tmp/fly_assembly.finished
	if [ ! -f results/0052_metagenome_assembly_by_fly/tmp/fly_assembly.finished ] ; then 
		for sublist in $( ls results/0052_metagenome_assembly_by_fly/tmp/lists/ ) ; do
			echo $sublist
			sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0052_metagenome_assembly_by_fly.sbatch | sed "s#XYZ#$fastq_file_path#g" > results/0052_metagenome_assembly_by_fly/tmp/sbatch/0052_metagenome_assembly_by_fly.$sublist.sbatch
			sbatch results/0052_metagenome_assembly_by_fly/tmp/sbatch/0052_metagenome_assembly_by_fly.$sublist.sbatch
		done
		echo "step-01: fly assembly finished" > results/0052_metagenome_assembly_by_fly/tmp/fly_assembly.finished
	fi
###############################################################################
## step-02: wait untill assembly is finished
	if [ -f results/0052_metagenome_assembly_by_fly/tmp/fly_assembly.finished ] ; then 
		counter=0
		max_attempts=180  # 60 attempts * 1 minute = 1 hour

		cat $list > results/0052_metagenome_assembly_by_fly/tmp/tmp.list

		while [ $counter -lt $max_attempts ] && [ -s results/0052_metagenome_assembly_by_fly/tmp/tmp.list ] ; do
			for F1 in $(cat results/0052_metagenome_assembly_by_fly/tmp/tmp.list); do
				if [ -e "results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta" ] || grep -q "ERROR: Pipeline aborted" results/0052_metagenome_assembly_by_fly/raw_files/$F1/flye.log ; then
					sed -i "/$F1/d" results/0052_metagenome_assembly_by_fly/tmp/tmp.list
					echo "fly assembly process $F1 finished"
					break
					else
					echo "fly assembly $F1 not finished in $counter minutes"
					echo "waiting for 1 more minute and will check again (will wait maximum $max_attempts minutes)"
					sleep 60
					counter=$((counter + 1))
				fi
			done
		done

		if [ $counter -eq $max_attempts ]; then
			echo "File not found after 3 hour. Exiting..."
		fi

		# rm results/0052_metagenome_assembly_by_fly/tmp/tmp.list
		sleep 60 ## needed for the files to be writen
		echo "fly assembly finished" > results/0052_metagenome_assembly_by_fly/tmp/fly_assembly.finished
	fi 
###############################################################################
## step-03: run metaquast
	echo "running metaquast "
    for F1 in $(cat $list); do  
		if [ -f results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta ] ; then 
			if [ ! -d results/0052_metagenome_assembly_by_fly/raw_files/$F1/quast/fasta ] ; then 
				echo "metaquast for $F1: running"
				mkdir -p results/0052_metagenome_assembly_by_fly/raw_files/$F1/quast/fasta
				cp results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta \
				results/0052_metagenome_assembly_by_fly/raw_files/$F1/quast/fasta/

				cp results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta \
				results/0052_metagenome_assembly_by_fly/all_fasta/$F1.fasta

				( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
				-o results/0052_metagenome_assembly_by_fly/raw_files/$F1/quast/ \
				results/0052_metagenome_assembly_by_fly/raw_files/$F1/quast/fasta/*  ) > /dev/null 2>&1
				else
				echo "metaquast for $F1: already finished" 
			fi
		fi
    done 

	for F1 in $(cat $list); do  
		if [ -f results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta ] ; then 
			awk -F'\t' '{print $2}' results/0052_metagenome_assembly_by_fly/raw_files/$F1/quast/report.tsv | sed "s/assembly/$F1/g" \
			> results/0052_metagenome_assembly_by_fly/tmp/$F1.metaquast.txt 
			else
			echo $F1.contigs > results/0052_metagenome_assembly_by_fly/tmp/$F1.metaquast.txt 
			for i in {1..22}; do echo "na" >> results/0052_metagenome_assembly_by_fly/tmp/$F1.metaquast.txt ; done
		fi 
	done 
	paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt results/0052_metagenome_assembly_by_fly/tmp/*.metaquast.txt \
	> results/0052_metagenome_assembly_by_fly/summary.tsv

###############################################################################
## step-03: send report by email (with attachment)

    echo "sending email"
    user=$(whoami)
    user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0052_metagenome_assembly_by_fly.py -e $user_email

    deactivate
###############################################################################
echo "script 0052_genome_assembly_by_fly ended --------------------------------------"
###############################################################################
