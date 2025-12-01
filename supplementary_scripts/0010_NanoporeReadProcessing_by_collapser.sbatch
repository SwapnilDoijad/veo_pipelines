#!/bin/bash
#SBATCH --job-name=0010_NanoporeReadProcessing_by_collapser
#SBATCH --partition=long
#SBATCH --output=results/0010_NanoporeReadProcessing_by_collapser/tmp/slurm/%j.out
#SBATCH --error=results/0010_NanoporeReadProcessing_by_collapser/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=200G
###############################################################################
## step-01: preparation
    pipeline=0010_NanoporeReadProcessing_by_collapser
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fastq_file_path=$(grep my_fastq_path $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC

	echo "fastq_file_path: $fastq_file_path"
###############################################################################
	log "STARTED: $pipeline -----------------------------" 
###############################################################################
    source /vast/xa73pav/projects/p_swapnil_Collapser/venv/bin/activate

	mkdir -p $raw_files/fastq
    for i in $(cat $sublist); do
		if [ ! -d $raw_files/$i ] ; then 
			log "STARTED: $i"

			mkdir -p $raw_files/$i

			log "Running Collapser for $i"

			python3.9 /vast/xa73pav/projects/p_swapnil_Collapser/scripts/Collapser.py \
			$fastq_file_path/$i.fastq.gz \
			$i \
			--out-dir $raw_files/$i \
			--dotplot \
			--rc-repeats \
			--direct-repeats \
			--bin-size 300 \
			--max-gap 1000 \
			--min-pct-id 90 \
			--min-length 2000 \
			--jobs 1 \
			--workers $SLURM_CPUS_PER_TASK \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.Collapser.tsv 

			log "FINISHED: $i"

		else
		log "ALREADY FINISHED: $i"
		fi
	done

	for i in $(cat $sublist); do
		log "Cutting sequences for $i"

		python3.9 /vast/xa73pav/projects/p_swapnil_Collapser/scripts/cut_sequences.py \
		--input-type fastq \
		--input-file $fastq_file_path/$i.fastq.gz \
		--coords-dir $raw_files/$i \
		--out-dir $wd/fastq \
		--threads $SLURM_CPUS_PER_TASK \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/$i.cut_sequences.tsv 

		log "Finished cutting sequences for $i"
	done

	for  i in $(cat $sublist); do
		log "calculating read counts for $i"
		raw_reads=$(count_reads_from_fastq "$fastq_file_path/$i.fastq.gz")
		collapsed_reads=$(find $raw_files/$i -maxdepth 1 -type f -name '*.png' | wc -l)

		echo  "$i $raw_reads $collapsed_reads" | tee -a $raw_files/collapser_summary.txt
	done

    deactivate
############################################################################### 
	log "FINISHED: $pipeline -----------------------------" && clean
###############################################################################

