#!/bin/bash
###############################################################################
## header
	pipeline=0445_genome_assembly_for_nanopore_for_phage_by_canu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline ------------------------------------------"
###############################################################################
## step-01: preparation

    ## tool path
    my_tool_path=/home/groups/VEO/tools/canu/v2.2/canu-2.2/bin

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		read l
		list=$(echo "list.$l.txt")
	fi

	(mkdir -p $wd/tmp ) > /dev/null 2>&1
	(mkdir -p $wd/all_fasta ) > /dev/null 2>&1
    (mkdir -p $wd/raw_files ) > /dev/null 2>&1
###############################################################################
## step-02: canu assembly
	log "STARTED: step-02 : canu assembly"
    for F1 in $(cat $list); do
        if [ ! -d $wd/raw_files/$F1 ] ; then 
            log "STARTED : long-read assembly by canu for $F1"
            $my_tool_path/canu \
            -p $F1 -d $wd/raw_files/$F1 \
			genomeSize=0.06m maxInputCoverage=10000 \
			minReadLength=1000 minOverlapLength=500 \
            -nanopore $data_directory_fastq_path/$F1.fastq.gz
            else
            log "ALREADY FINISHED : long-read assembly by canu for $F1"
        fi
	done
###############################################################################
# 		max_wait_time=$((3 * 60 * 60))
# 		start_time=$(date +%s)
#     for F1 in $(cat $list); do
# 		# Loop until either the desired string is found or three hours have passed
# 		while true; do
# 			# Check if the maximum wait time has been exceeded
# 			current_time=$(date +%s)
# 			elapsed_time=$((current_time - start_time))
# 			if [ $elapsed_time -ge $max_wait_time ]; then
# 				log "Maximum wait time exceeded. Exiting."
# 				break
# 			fi

# 			if [ -e "$wd/raw_files/$F1/canu.out" ] ; then 
# 				if tail -n 1 "$wd/raw_files/$F1/canu.out" | grep -q -- "-- Bye."; then
# 					log "FINISHED : $F1 assembly by canu"
# 					break
# 					else
# 					log "WAITING : $F1 assembly by canu"
# 					sleep 10
# 				fi
# 			else
# 				log "WAITING : $wd/raw_files/$F1/canu.out not found"
# 				sleep 10
# 			fi

# 		done
# 	done 
# ###############################################################################
# ## step-03: get the stat of fasta 

# 	echo -e "Id\tnumber_of_contigs\tassembly_length" > $wd/summary.tsv
#     for F1 in $(cat $list); do
# 		if [ -f $wd/raw_files/$F1/$F1.contigs.fasta ] ; then 
# 		cp $wd/raw_files/$F1/$F1.contigs.fasta $wd/all_fasta/$F1.fasta 
# 		number_of_contigs=$(grep ">" $wd/raw_files/$F1/$F1.contigs.fasta | wc -l )
# 		assembly_length=$(grep -v '>' $wd/raw_files/$F1/$F1.contigs.fasta | tr -d '\n' | wc -c )
# 		echo -e "$F1\t$number_of_contigs\t$assembly_length" >> $wd/summary.tsv
# 		else
# 		echo -e "$F1\t0\t0" >> $wd/summary.tsv
# 		fi 
# 	done
# ###############################################################################
# ## step-04: run metaquast
# 	if [ ! -f $wd/summary.2.tsv ] ; then 
# 		for F1 in $(cat $list); do  
# 			if [ -f $wd/raw_files/$F1/$F1.contigs.fasta ] ; then 
# 				if [ ! -d $wd/raw_files/$F1/quast/fasta ] ; then 
# 					log "STARTED : metaquast for $F1"
# 					mkdir -p $wd/raw_files/$F1/quast/fasta
# 					cp $wd/raw_files/$F1/$F1.contigs.fasta \
# 					$wd/raw_files/$F1/quast/fasta/

# 					cp $wd/raw_files/$F1/$F1.contigs.fasta \
# 					$wd/all_fasta/$F1.fasta

# 					( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
# 					-o $wd/raw_files/$F1/quast/ \
# 					$wd/raw_files/$F1/quast/fasta/*  ) > /dev/null 2>&1
# 					log "FINISHED : metaquast for $F1"
# 					else
# 					log "ALREADY FINISHED : metaquast for $F1" 
# 				fi
# 			fi
# 		done 

# 		for F1 in $(cat $list); do  
# 			while [ ! -f $wd/raw_files/$F1/quast/report.tsv ] ; do  
# 				sleep 5
# 			done 

# 			if [ -f $wd/raw_files/$F1/$F1.contigs.fasta ] ; then 
# 				awk -F'\t' '{print $2}' $wd/raw_files/$F1/quast/report.tsv | sed "s/assembly/$F1/g" \
# 				> $wd/tmp/$F1.metaquast.txt 
# 				else
# 				echo $F1.contigs > $wd/tmp/$F1.metaquast.txt 
# 				for i in {1..22}; do echo "na" >> $wd/tmp/$F1.metaquast.txt ; done
# 			fi 
# 		done 
# 		paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt $wd/tmp/*.metaquast.txt \
# 		> $wd/summary.2.tsv
# 	fi 
###############################################################################
## footer
	log "ENDED : $pipeline --------------------------------------------"
##############################################################################


## unused script
###############################################################################
## step-02: post-assembly statistics and coverting fasta files
	# for F1 in $(cat $list); do
	# 	if [ -f  $wd/all_fasta/assembly.fasta ]; then
	# 		cp $wd/raw_files/$F1/assembly.fasta $wd/raw_files/$F1/$F1.joined.fasta
	# 		sed -i 's/>.*/NNNNNNNNNN/g' $wd/raw_files/$F1/$F1.joined.fasta
	# 		sed -i "1i "'>'$F1"" $wd/raw_files/$F1/$F1.joined.fasta
	# 		sed -i "\$aNNNNNNNNNN" $wd/raw_files/$F1/$F1.joined.fasta
	# 		cp $wd/raw_files/$F1/$F1.joined.fasta $wd/all_fasta/$F1.fasta
	# 	fi
	# done
###############################################################################
## step-03: count the length of the fasta 
 	# if [ ! -f $wd/stat.tab ] ; then 
	# 	echo -e "id\tfasta_length" > $wd/stat.tab
	# 	for i in $(cat $list ) ; do 
	# 		fasta_length=$( grep -v '^>' $wd/all_fasta/$i.fasta | tr -d '\n' | wc -c )
	# 		echo -e "$i\t$fasta_length" >> $wd/stat.tab
	# 	done 
	# fi

###############################################################################
