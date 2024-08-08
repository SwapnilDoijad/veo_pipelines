#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : 0048_genome_assembly_by_flye ------------------------------------------"
###############################################################################
## step-00: preparation
	wd=results/0048_genome_assembly_by_flye

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

	(mkdir -p $wd/all_fasta ) > /dev/null 2>&1
    (mkdir -p $wd/raw_files ) > /dev/null 2>&1
	(mkdir -p $wd/tmp/lists ) > /dev/null 2>&1
	(mkdir -p $wd/tmp/sbatch ) > /dev/null 2>&1

    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 3 ))
    split -l "$lines_per_part" "$list" list.0052.fastq_
    mv list.0052.fastq_* $wd/tmp/lists/

###############################################################################
## step-01: flye assembly
	## for re-running 
	## rm $wd/tmp/flye_assembly.finished
	if [ ! -f $wd/tmp/flye_assembly.finished ] ; then 
		for sublist in $( ls $wd/tmp/lists/ ) ; do
			sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0048_genome_assembly_by_flye.sbatch | sed "s#XYZ#$fastq_file_path#g" > $wd/tmp/sbatch/0048_genome_assembly_by_flye.$sublist.sbatch
			( sbatch $wd/tmp/sbatch/0048_genome_assembly_by_flye.$sublist.sbatch ) > /dev/null 2>&1
			log "SUBMITTED : flye sbatch for $sublist"
		done
		echo "step-01: flye assembly finished" > $wd/tmp/flye_assembly.finished
	fi
###############################################################################
## step-02: wait untill assembly is finished
	if [ -f $wd/tmp/flye_assembly.finished ] ; then 
		counter=0
		max_attempts=180  # 60 attempts * 1 minute = 1 hour

		cat $list > $wd/tmp/tmp.list

		while [ $counter -lt $max_attempts ] && [ -s $wd/tmp/tmp.list ] ; do
			for F1 in $(cat $wd/tmp/tmp.list); do
				if [ -e "results/0048_genome_assembly_by_flye/raw_files/$F1/assembly.fasta" ] || grep -q "ERROR: Pipeline aborted" $wd/raw_files/$F1/flye.log ; then
					sed -i "/$F1/d" $wd/tmp/tmp.list
					log "FINISHED : assembly by flye for $F1"
					break
					else
					log "WAITING : assembly by flye for $F1 (not finished in $counter / $max_attempts minutes)"
					sleep 60
					counter=$((counter + 1))
				fi


				if [ $counter -eq $max_attempts ]; then
					log "ERROR : assembly for $F1 not finished in 3 hours. Assembly failed? exiting..."
				fi

			done
		done

		# rm $wd/tmp/tmp.list
		sleep 60 ## needed for the files to be writen
		echo "flye assembly finished" > $wd/tmp/flye_assembly.finished
	fi 
###############################################################################
## step-03: run metaquast
	log "running metaquast "
	if [ ! -f $wd/summary.2.tsv ] ; then 
		for F1 in $(cat $list); do  
			if [ -f $wd/raw_files/$F1/assembly.fasta ] ; then 
				if [ ! -d $wd/raw_files/$F1/quast/fasta ] ; then 
					log "metaquast for $F1: running"
					mkdir -p $wd/raw_files/$F1/quast/fasta
					cp $wd/raw_files/$F1/assembly.fasta \
					results/0048_genome_assembly_by_flye/raw_files/$F1/quast/fasta/

					cp $wd/raw_files/$F1/assembly.fasta \
					results/0048_genome_assembly_by_flye/all_fasta/$F1.fasta

					( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
					-o $wd/raw_files/$F1/quast/ \
					results/0048_genome_assembly_by_flye/raw_files/$F1/quast/fasta/*  ) > /dev/null 2>&1
					else
					log "metaquast for $F1: already finished" 
				fi
			fi
		done 

		for F1 in $(cat $list); do  
			if [ -f $wd/raw_files/$F1/assembly.fasta ] ; then 
				awk -F'\t' '{print $2}' $wd/raw_files/$F1/quast/report.tsv | sed "s/assembly/$F1/g" \
				> $wd/tmp/$F1.metaquast.txt 
				else
				echo $F1.contigs > $wd/tmp/$F1.metaquast.txt 
				for i in {1..22}; do echo "na" >> $wd/tmp/$F1.metaquast.txt ; done
			fi 
		done 
		paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt $wd/tmp/*.metaquast.txt \
		> $wd/summary.2.tsv
	fi 
###############################################################################
## step-04: count number of contigs and the length of the fasta 
 	if [ ! -f $wd/summary.tsv ] ; then 
		log "RUNNING : step-04: count number of contigs and the length of the fasta"
		echo -e "id\tnumber_of_contigs\tfasta_length" > $wd/summary.tsv
		for i in $(cat $list ) ; do 
			if [ -f $wd/raw_files/$i/assembly.fasta ]; then
				number_of_contigs=$(grep -c ">" $wd/raw_files/$i/assembly.fasta | awk '{print $1}' )
				fasta_length=$( grep -v '^>' $wd/raw_files/$i/assembly.fasta | tr -d '\n' | wc -c )
				echo -e "$i\t$number_of_contigs\t$fasta_length" >> $wd/summary.tsv
				else
				echo -e "$i\t0\t0" >> $wd/summary.tsv
			fi
		done 
		log "FINISHED : step-04: count number of contigs and the length of the fasta"
		else
		log "ALREADY FINISHED: step-04: count number of contigs and the length of the fasta"
	fi
###############################################################################
## step-03: send report by email (with attachment)

    # echo "sending email"
    # user=$(whoami)
    # user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    # source /home/groups/VEO/tools/email/myenv/bin/activate

    # python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0048_genome_assembly_by_flye.py -e $user_email

    # deactivate
###############################################################################
## footer
	log "ENDED : 0048_genome_assembly_by_flye --------------------------------------------"
##############################################################################
