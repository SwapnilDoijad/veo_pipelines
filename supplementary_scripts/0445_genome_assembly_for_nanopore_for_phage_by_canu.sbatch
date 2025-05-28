#!/bin/bash
#SBATCH --job-name=0445_genome_assembly_for_nanopore_for_phage_by_canu
#SBATCH --partition=standard,long,interactive
#SBATCH --output=results/0445_genome_assembly_for_nanopore_for_phage_by_canu/tmp/slurm/%j.out
#SBATCH --error=results/0445_genome_assembly_for_nanopore_for_phage_by_canu/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0445_genome_assembly_for_nanopore_for_phage_by_canu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline ------------------------------------------"
###############################################################################
## step-01: preparation
	sublist=results/$pipeline/tmp/lists/ABC
    my_tool_path=/home/groups/VEO/tools/canu/v2.2/canu-2.2/bin
	fastq_path=$( grep my_fastq_dir $parameters | awk '{print $2}' )

	(mkdir -p $wd/tmp $wd/all_fasta $wd/raw_files ) > /dev/null 2>&1
###############################################################################
## step-02: canu assembly
	log "STARTED: step-02 : canu assembly"
    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/$i.contigs.fasta ] ; then 
            log "STARTED : long-read assembly by canu for $i"
            $my_tool_path/canu \
			useGrid=false \
			cnsMemory=200 \
			cnsThreads=40 \
            -p $i -d $wd/raw_files/$i \
			corOutCoverage=100 \
			"batOptions=-dg 3 -db 3 -dr 1 -ca 500 -cp 50" \
			genomeSize=0.06m maxInputCoverage=10000 \
			minReadLength=1000 minOverlapLength=500 \
            -nanopore $fastq_path/$i.fastq.gz

            else
            log "ALREADY FINISHED : long-read assembly by canu for $i"
        fi
	done

    for i in $(cat $sublist); do
		contigs=$(grep -c ">" $raw_files/$i/$i.contigs.fasta || echo 0)
		length=$(grep -v ">" $raw_files/$i/$i.contigs.fasta | tr -d '\n' | wc -c || echo 0)
		echo -e "$i\t$contigs\t$length" | tee -a $wd/summary.tsv
	done

###############################################################################
# 		max_wait_time=$((3 * 60 * 60))
# 		start_time=$(date +%s)
#     for i in $(cat $list); do
# 		# Loop until either the desired string is found or three hours have passed
# 		while true; do
# 			# Check if the maximum wait time has been exceeded
# 			current_time=$(date +%s)
# 			elapsed_time=$((current_time - start_time))
# 			if [ $elapsed_time -ge $max_wait_time ]; then
# 				log "Maximum wait time exceeded. Exiting."
# 				break
# 			fi

# 			if [ -e "$wd/raw_files/$i/canu.out" ] ; then 
# 				if tail -n 1 "$wd/raw_files/$i/canu.out" | grep -q -- "-- Bye."; then
# 					log "FINISHED : $i assembly by canu"
# 					break
# 					else
# 					log "WAITING : $i assembly by canu"
# 					sleep 10
# 				fi
# 			else
# 				log "WAITING : $wd/raw_files/$i/canu.out not found"
# 				sleep 10
# 			fi

# 		done
# 	done 
# ###############################################################################
# ## step-03: get the stat of fasta 

# 	echo -e "Id\tnumber_of_contigs\tassembly_length" > $wd/summary.tsv
#     for i in $(cat $list); do
# 		if [ -f $wd/raw_files/$i/$i.contigs.fasta ] ; then 
# 		cp $wd/raw_files/$i/$i.contigs.fasta $wd/all_fasta/$i.fasta 
# 		number_of_contigs=$(grep ">" $wd/raw_files/$i/$i.contigs.fasta | wc -l )
# 		assembly_length=$(grep -v '>' $wd/raw_files/$i/$i.contigs.fasta | tr -d '\n' | wc -c )
# 		echo -e "$i\t$number_of_contigs\t$assembly_length" >> $wd/summary.tsv
# 		else
# 		echo -e "$i\t0\t0" >> $wd/summary.tsv
# 		fi 
# 	done
# ###############################################################################
# ## step-04: run metaquast
# 	if [ ! -f $wd/summary.2.tsv ] ; then 
# 		for i in $(cat $list); do  
# 			if [ -f $wd/raw_files/$i/$i.contigs.fasta ] ; then 
# 				if [ ! -d $wd/raw_files/$i/quast/fasta ] ; then 
# 					log "STARTED : metaquast for $i"
# 					mkdir -p $wd/raw_files/$i/quast/fasta
# 					cp $wd/raw_files/$i/$i.contigs.fasta \
# 					$wd/raw_files/$i/quast/fasta/

# 					cp $wd/raw_files/$i/$i.contigs.fasta \
# 					$wd/all_fasta/$i.fasta

# 					( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
# 					-o $wd/raw_files/$i/quast/ \
# 					$wd/raw_files/$i/quast/fasta/*  ) > /dev/null 2>&1
# 					log "FINISHED : metaquast for $i"
# 					else
# 					log "ALREADY FINISHED : metaquast for $i" 
# 				fi
# 			fi
# 		done 

# 		for i in $(cat $list); do  
# 			while [ ! -f $wd/raw_files/$i/quast/report.tsv ] ; do  
# 				sleep 5
# 			done 

# 			if [ -f $wd/raw_files/$i/$i.contigs.fasta ] ; then 
# 				awk -F'\t' '{print $2}' $wd/raw_files/$i/quast/report.tsv | sed "s/assembly/$i/g" \
# 				> $wd/tmp/$i.metaquast.txt 
# 				else
# 				echo $i.contigs > $wd/tmp/$i.metaquast.txt 
# 				for i in {1..22}; do echo "na" >> $wd/tmp/$i.metaquast.txt ; done
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
	# for i in $(cat $list); do
	# 	if [ -f  $wd/all_fasta/assembly.fasta ]; then
	# 		cp $wd/raw_files/$i/assembly.fasta $wd/raw_files/$i/$i.joined.fasta
	# 		sed -i 's/>.*/NNNNNNNNNN/g' $wd/raw_files/$i/$i.joined.fasta
	# 		sed -i "1i "'>'$i"" $wd/raw_files/$i/$i.joined.fasta
	# 		sed -i "\$aNNNNNNNNNN" $wd/raw_files/$i/$i.joined.fasta
	# 		cp $wd/raw_files/$i/$i.joined.fasta $wd/all_fasta/$i.fasta
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
