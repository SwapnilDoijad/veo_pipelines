#!/bin/bash
#SBATCH --job-name=0010_NanoporeReadProcessing_by_collapser
#SBATCH --partition=standard,long,interactive,gpu-veo,gpu,gpu-test,fat
#SBATCH --output=results/0010_NanoporeReadProcessing_by_collapser/tmp/slurm/%j.out
#SBATCH --error=results/0010_NanoporeReadProcessing_by_collapser/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
###############################################################################
## step-01: preparation
    pipeline=0010_NanoporeReadProcessing_by_collapser
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fastq_file_path=$(grep my_fastq_path $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC
###############################################################################
	log "STARTED: $pipeline -----------------------------" 
###############################################################################
    source /vast/xa73pav/projects/p_swapnil_Collapser/venv/bin/activate

	mkdir -p $raw_files/fastq
    for i in $(cat $sublist); do
		log "STARTED: $i"

		mkdir -p $raw_files/$i

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
		--jobs $SLURM_CPUS_PER_TASK


		python3.9 scripts/cut_sequences.py \
		--input-type fastq \
		--input-file $input_dir/$i.fastq.gz \
		--coords-dir $raw_files/$i \
		--out-dir $output_dir/fastq \
		--threads $SLURM_CPUS_PER_TASK

		raw_reads=$(count_reads_from_fastq "$input_dir/$i.fastq.gz")
		collapsed_reads=$(find $output_dir/raw_files/$i -maxdepth 1 -type f -name '*.png' | wc -l)

		echo  "$i $raw_reads $collapsed_reads" | tee -a $raw_files/collapser_summary.txt
	done

    deactivate
############################################################################### 
	log "FINISHED: $pipeline -----------------------------" # && clean
###############################################################################

