#!/bin/bash
###############################################################################
echo "script 0051_metagenome_assembly_by_canu started ------------------------------------"
###############################################################################
## step-00: preparation

    ## tool path
    my_tool_path=/home/groups/VEO/tools/canu/v2.2/canu-2.2/bin

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

	(mkdir -p results/0051_metagenome_assembly_by_canu/all_fasta ) > /dev/null 2>&1
    (mkdir -p results/0051_metagenome_assembly_by_canu/raw_files ) > /dev/null 2>&1
	(mkdir -p results/0051_metagenome_assembly_by_canu/tmp ) > /dev/null 2>&1
###############################################################################
## step-01: canu assembly
	## paramteres were set as per developers recommendeation for metagenome assembly
	## https://github.com/marbl/canu/issues/634
	## and https://canu.readthedocs.io/en/latest/faq.html

			# corMaxEvidenceCoverageLocal=10 \
			# corMaxEvidenceCoverageGlobal=10 \
    for F1 in $(cat $list); do
        if [ ! -f results/0051_metagenome_assembly_by_canu/raw_files/$F1/$F1.contigs.fasta ] ; then 
            echo "long-read assembly by canu for $F1 : running"
            $my_tool_path/canu \
            -p $F1 -d results/0051_metagenome_assembly_by_canu/raw_files/$F1 \
			genomeSize=5m \
			minInputCoverage=0.01 \
			maxInputCoverage=10000 \
			corMinCoverage=0 \
			corOutCoverage=10000 \
			corMhapSensitivity=high \
			correctedErrorRate=0.105 \
			stopOnLowCoverage=0.01 \
			cnsMaxCoverage=0 \
			oeaMemory=100 \
			redMemory=100 \
			batMemory=200 \
            -nanopore $fastq_file_path/$F1.fastq.gz
            else
            echo "long-read assembly by canu for $F1 : already finished"
        fi
	done
###############################################################################
## step-02: wait untill assembly is finished
	rm results/0051_metagenome_assembly_by_canu/tmp/canu_assembly.finished
	if [ ! -f results/0051_metagenome_assembly_by_canu/tmp/canu_assembly.finished ] ; then 
		counter=0
		max_attempts=180  # 60 attempts * 1 minute = 1 hour

		cat $list > results/0051_metagenome_assembly_by_canu/tmp/tmp.list

		while [ $counter -lt $max_attempts ] && [ -s results/0051_metagenome_assembly_by_canu/tmp/tmp.list ] ; do
			for F1 in $(cat results/0051_metagenome_assembly_by_canu/tmp/tmp.list); do
				if [ -f "results/0051_metagenome_assembly_by_canu/raw_files/$F1/$F1.contigs.fasta" ] || grep -q "ABORT:" results/0051_metagenome_assembly_by_canu/raw_files/$F1/canu.out ; then
					sed -i "/$F1/d" results/0051_metagenome_assembly_by_canu/tmp/tmp.list
					echo "canu assembly $F1 finished, no more waiting"
					break
					else
					echo "canu assembly $F1 not finished in $counter minutes"
					echo "waiting for 1 more minute and will check again (will wait maximum $max_attempts minutes)"
					sleep 60
					counter=$((counter + 1))
				fi
			done
		done

		if [ $counter -eq $max_attempts ]; then
			echo "File not found after 3 hour. Exiting..."
		fi

		rm results/0051_metagenome_assembly_by_canu/tmp/tmp.list
		sleep 60 ## needed for the files to be writen, it takes time for the canu 
		echo "canu assembly finished" > results/0051_metagenome_assembly_by_canu/tmp/canu_assembly.finished
	fi 
	
###############################################################################
## step-02: run metaquast
	echo "running metaquast "
    for F1 in $(cat $list); do  
		if [ -f results/0051_metagenome_assembly_by_canu/raw_files/$F1/$F1.contigs.fasta ] ; then 
			if [ ! -d results/0051_metagenome_assembly_by_canu/raw_files/$F1/quast/fasta ] ; then 
				echo "metaquast for $F1: running"
				mkdir -p results/0051_metagenome_assembly_by_canu/raw_files/$F1/quast/fasta
				cp results/0051_metagenome_assembly_by_canu/raw_files/$F1/$F1.contigs.fasta results/0051_metagenome_assembly_by_canu/raw_files/$F1/quast/fasta/

				cp results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta \
				results/0052_metagenome_assembly_by_fly/all_fasta/$F1.fasta

				python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
				-o results/0051_metagenome_assembly_by_canu/raw_files/$F1/quast/ \
				results/0051_metagenome_assembly_by_canu/raw_files/$F1/quast/fasta/* 
				else
				echo "metaquast for $F1: already finished"
			fi
		fi
    done 

	for F1 in $(cat $list); do  
		if [ -f results/0051_metagenome_assembly_by_canu/raw_files/$F1/$F1.contigs.fasta ] ; then 
			awk -F'\t' '{print $2}' results/0051_metagenome_assembly_by_canu/raw_files/$F1/quast/report.tsv \
			> results/0051_metagenome_assembly_by_canu/tmp/$F1.metaquast.txt 
			else
			echo $F1.contigs > results/0051_metagenome_assembly_by_canu/tmp/$F1.metaquast.txt 
			for i in {1..22}; do echo "na" >> results/0051_metagenome_assembly_by_canu/tmp/$F1.metaquast.txt ; done
		fi 
	done 
	paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt results/0051_metagenome_assembly_by_canu/tmp/*.metaquast.txt \
	> results/0051_metagenome_assembly_by_canu/summary.tsv
###############################################################################
## step-03: send report by email (with attachment)

    echo "sending email"
    user=$(whoami)
    user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0051_metagenome_assembly_by_canu.py -e $user_email

    deactivate
###############################################################################
echo "script 0051_metagenome_assembly_by_canu ended --------------------------------------"
###############################################################################


