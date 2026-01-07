#!/bin/bash
#SBATCH --job-name=0039_genome_assembly_by_unicycler_hybrid
#SBATCH --partition=gpu-veo,gpu-test,standard,long,gpu,fat
#SBATCH --output=results/0039_genome_assembly_by_unicycler_hybrid/tmp/slurm/%j.out
#SBATCH --error=results/0039_genome_assembly_by_unicycler_hybrid/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header 
	pipeline=0039_genome_assembly_by_unicycler_hybrid
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	sublist=$wd/tmp/lists/ABC
	long_read_id_list=$(cat $sublist | awk '{print $1}' | awk -F'/' '{print $NF}' | sed 's/.fastq.gz//g')

    log "STARTED: $pipeline : $sublist"
###############################################################################
## step-02: unicycler assembly
	source /home/groups/VEO/tools/biopython/myenv/bin/activate
	while IFS=$'\t' read -r long_read illumina_R1 illumina_R2 ; do 
		id=$(echo $long_read | awk -F'/' '{print $NF}' | sed 's/.fastq.gz//g')

		if [ ! -f $raw_files/$id/assembly.fasta ]; then
			log "STARTED: hybrid assembly for $id"

			python3.6 /home/groups/VEO/tools/unicycler/v0.5.0/unicycler-runner.py \
			-1 $illumina_R1 \
			-2 $illumina_R2 \
			-l $long_read \
			-o $raw_files/$id \
			--spades_path /home/groups/VEO/tools/SPAdes/v3.15.5/bin/spades.py \
			--racon_path /home/groups/VEO/tools/racon/v1.5.0/build/bin/racon \
			--tblastn_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/tblastn \
			--makeblastdb_path /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
			--keep 0 \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$id.unicycler.tsv 

			## as per graph, split contigs by component and merge (by 10N) those belong to a single component
			python $suppl_scripts/$pipeline.split_by_component.py \
            -i $raw_files/${i}/assembly.fasta \
            -g $raw_files/${i}/assembly.gfa \
            -o $raw_files/${i}/${i}

            cat $raw_files/${i}/${i}_*.fasta \
            > $raw_files/${i}/assembly.final.fasta

			log "FINISHED: hybrid assembly for $id"

			else
			log "ALREADY FINISHED: hybrid assembly for $id"
		fi
	done < $sublist
	deactivate
###############################################################################
## step-03: post-assembly statistics and converting fasta files
	for F1 in $long_read_id_list; do
		if [ ! -f $wd/all_fasta/$F1.fasta ] ; then 
			if [ -f $raw_files/$F1/assembly.fasta ]; then
				log "copying files to all_fasta and all_fasta_joined"
				cp $raw_files/$F1/assembly.final.fasta $wd/all_fasta/$F1.fasta
			fi
		fi
	done

###############################################################################
## step-04: count the length of the fasta 

	log -e "id\tnumber_of_contigs\tfasta_length" > $wd/summary.tsv
	for i in $long_read_id_list; do
		if [ -f $raw_files/$i/assembly.fasta ]; then
			number_of_contigs=$(grep -c ">" $wd/all_fasta/$i.fasta | awk '{print $1}' )
			fasta_length=$( grep -v '^>' $wd/all_fasta/$i.fasta | tr -d '\n' | wc -c )
			echo -e "$i\t$number_of_contigs\t$fasta_length" >> $wd/summary.tsv
			else
			echo -e "$i\t0\t0" >> $wd/summary.tsv
		fi
	done 

###############################################################################
## step-05: run metaquast

	for F1 in $long_read_id_list; do
		if [ -f $raw_files/$F1/assembly.fasta ] ; then 
			if [ ! -d $raw_files/$F1/quast/fasta ] ; then 
				log "STARTED : metaquast for $F1"
				mkdir -p $raw_files/$F1/quast/fasta
				cp $raw_files/$F1/assembly.final.fasta \
				$raw_files/$F1/quast/fasta/

				cp $raw_files/$F1/assembly.final.fasta \
				$wd/all_fasta/$F1.fasta

				get_resource_stat "$wd"/tmp/resource_log/$F1.metaquast.tsv \
				python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
				-o $raw_files/$F1/quast/ \
				$raw_files/$F1/quast/fasta/* 
				#> /dev/null 2>&1
				log "FINISHED : metaquast for $F1"
				else
				log "ALREADY FINISHED : metaquast for $F1" 
			fi
		fi
	done 

	for F1 in $long_read_id_list; do
		if [ -f $raw_files/$F1/assembly.fasta ] ; then 
			awk -F'\t' '{print $2}' $raw_files/$F1/quast/report.tsv | sed "s/assembly/$F1/g" \
			> $wd/tmp/$F1.metaquast.txt 
			else
			echo $F1.contigs > $wd/tmp/$F1.metaquast.txt 
			for i in {1..22}; do echo "na" >> $wd/tmp/$F1.metaquast.txt ; done
		fi 
	done 
	paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt $wd/tmp/*.metaquast.txt \
	> $wd/summary.2.tsv

###############################################################################
## footer
	log "ENDED : $pipeline : $sublist"
###############################################################################

