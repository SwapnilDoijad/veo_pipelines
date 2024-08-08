#!/bin/bash
###############################################################################
## header 
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: 0043_genome_assembly_by_unicycler -------------------------------------"
###############################################################################
## step-01: preparation

	wd=results/0043_genome_assembly_by_unicycler
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

	#echo "do you want to analyze the NCBI data"$ncbi"? type ncbi for yes" 
	#read ncbi_tmp
	#	if [ $ncbi_tmp = "ncbi" ] ; then
	#		ncbi=$(echo "/$ncbi_tmp")
	#		else
	#		ncbi=$(echo "")
	#	fi

	(mkdir -p $wd/tmp) > /dev/null 2>&1
	(mkdir -p $wd/all_fasta) > /dev/null 2>&1
	(mkdir -p $wd/all_fasta_joined) > /dev/null 2>&1
###############################################################################
## step-02: unicycler assembly
	# check short and long read, if both available
    for F1 in $(cat $list); do
		if [ ! -f $wd/raw_files/$F1/assembly.fasta ] ; then 
			if [ -f $path/results/02_filtered_reads/$F1/"$F1"_R1_001.filtered_paired.fastq.gz ] && [ -f $path/data"$ncbi"/long_read/raw_reads/"$SRABiosample_run".fastq.gz ] ; then
				echo "running hybrid assembly for $F1"
				WorDir=$(echo $PWD)
				python3.6 /home/groups/VEO/tools/unicycler/v0.5.0/unicycler-runner.py \
				-1 $path/results/02_filtered_reads/$F1/"$F1"_R1_001.filtered_paired.fastq.gz \
				-2 $path/results/02_filtered_reads/$F1/"$F1"_R2_001.filtered_paired.fastq.gz \
				-l $path/data"$ncbi"/long_reads/final_reads/"$F1".fastq.gz \
				-o $WorDir/$wd/raw_files/$F1 \
				--spades_path /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
				--racon_path /home/groups/VEO/tools/racon/v1.5.0/build/bin/racon \
				--keep 0
				cd $WorDir
				cp $wd/raw_files/$F1/assembly.fasta $wd/raw_files/$F1/$F1.joined.fasta
				sed -i 's/>.*/NNNNNNNNNN/g' $wd/raw_files/$F1/$F1.joined.fasta
				sed -i "1i "'>'$F1"" $wd/raw_files/$F1/$F1.joined.fasta
				sed -i "\$aNNNNNNNNNN" $wd/raw_files/$F1/$F1.joined.fasta
				cp $wd/raw_files/$F1/$F1.joined.fasta $wd/all_fasta/$F1.fasta
			elif [ -f $fastq_file_path/"$F1".fastq.gz ] ; then
				if [ ! -f $wd/raw_files/$F1/unicycler.log ] ; then 
					echo "running long-read assembly for $F1"
					WorDir=$(echo $PWD)
					python3.6 /home/groups/VEO/tools/unicycler/v0.5.0/unicycler-runner.py \
					-l $fastq_file_path/"$F1".fastq.gz \
					-o $WorDir/$wd/raw_files/$F1 \
					--spades_path /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
					--racon_path /home/groups/VEO/tools/racon/v1.5.0/build/bin/racon \
					--tblastn_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/tblastn \
					--makeblastdb_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
					--keep 0
					cd $WorDir
					else
					echo "long-read assembly for $F1 already finished"
				fi
			else
				echo "$path/data"$ncbi"/long_read/raw_reads/"$F1".fastq.gz"
				echo "Long-read or Long-short-read absent PLEASE CHECK ---------------"
				#echo "Long-read or Long-short-read absent PLEASE CHECK ---------------" > 0043_assembly_by_unicycler.failed.list
			fi
		fi 
	done
###############################################################################
# ## step : split each contig: 
# 	for F1 in $(cat $list ) ; do 
# 		mkdir -p $wd/raw_files/tmp_tmp
# 		/home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_fasta.pl \
# 		--input_file=$wd/raw_files/$F1/assembly.fasta \
# 		--output_dir=$wd/raw_files/tmp
# 		mv $wd/raw_files/tmp_tmp/*.fasta $wd/raw_files/$F1/
# 	done 
###############################################################################
## step-03: post-assembly statistics and converting fasta files
	for F1 in $(cat $list); do
		if [ ! -f $wd/all_fasta_joined/$F1.joined.fasta ] ; then 
			if [ -f $wd/raw_files/$F1/assembly.fasta ]; then
				echo "copying files to all_fasta and all_fasta_joined"
				cp $wd/raw_files/$F1/assembly.fasta $wd/all_fasta/$F1.fasta
				cp $wd/raw_files/$F1/assembly.fasta $wd/raw_files/$F1/$F1.joined.fasta
				sed -i 's/>.*/NNNNNNNNNN/g' $wd/raw_files/$F1/$F1.joined.fasta
				sed -i "1i "'>'$F1"" $wd/raw_files/$F1/$F1.joined.fasta
				sed -i "\$aNNNNNNNNNN" $wd/raw_files/$F1/$F1.joined.fasta
				cp $wd/raw_files/$F1/$F1.joined.fasta $wd/all_fasta_joined/$F1.joined.fasta
			fi
		fi
	done
###############################################################################
## step-04: count the length of the fasta 
 	if [ ! -f $wd/summary.tsv ] ; then 
		echo -e "id\tnumber_of_contigs\tfasta_length" > $wd/summary.tsv
		for i in $(cat $list ) ; do 
			if [ -f $wd/raw_files/$i/assembly.fasta ]; then
				number_of_contigs=$(grep -c ">" $wd/all_fasta/$i.fasta | awk '{print $1}' )
				fasta_length=$( grep -v '^>' $wd/all_fasta/$i.fasta | tr -d '\n' | wc -c )
				echo -e "$i\t$number_of_contigs\t$fasta_length" >> $wd/summary.tsv
				else
				echo -e "$i\t0\t0" >> $wd/summary.tsv
			fi
		done 
	fi
###############################################################################
## step-05: run metaquast
	if [ ! -f $wd/summary.2.tsv ] ; then 
		for F1 in $(cat $list); do  
			if [ -f $wd/raw_files/$F1/assembly.fasta ] ; then 
				if [ ! -d $wd/raw_files/$F1/quast/fasta ] ; then 
					log "STARTED : metaquast for $F1"
					mkdir -p $wd/raw_files/$F1/quast/fasta
					cp $wd/raw_files/$F1/assembly.fasta \
					$wd/raw_files/$F1/quast/fasta/

					cp $wd/raw_files/$F1/assembly.fasta \
					$wd/all_fasta/$F1.fasta

					( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
					-o $wd/raw_files/$F1/quast/ \
					$wd/raw_files/$F1/quast/fasta/*  ) > /dev/null 2>&1
					log "FINISHED : metaquast for $F1"
					else
					log "ALREADY FINISHED : metaquast for $F1" 
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
## footer
	log "ENDED : 0043_genome_assembly_by_unicycler --------------------------------------"
###############################################################################

