#!/bin/bash
#SBATCH --job-name=0659_phage_taxonomy_by_vclust
#SBATCH --partition=short,standard,long,interactive,gpu-test,gpu
#SBATCH --output=results/0659_phage_taxonomy_by_vclust/tmp/slurm/%j.out
#SBATCH --error=results/0659_phage_taxonomy_by_vclust/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0659_phage_taxonomy_by_vclust
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	vclust="python3.9 $tools/vclust/v1.2.7/vclust/vclust.py"
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: file and directory preparation
	cat	$fasta_directory/*.fasta | sed 's/:/_/g' | sed 's/,//g' > $raw_files/all.fna
	cat /veodata/03/databases/ictv/VMR_MSL39.v4_20241106.fna >> $raw_files/all.fna

	## Prefilter similar genome sequence pairs before conducting pairwise alignments.
	log "Prefiltering similar genome sequence pairs..."
	$vclust \
	prefilter \
	-i $raw_files/all.fna \
	-o $raw_files/fltr.txt \
	-t $SLURM_CPUS_PER_TASK \
	--k 21 --min-kmers 1 --min-ident 0.74 \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/vclust.prefilter.tsv

## Align similar genome sequence pairs and calculate pairwise ANI measures.
	log "Aligning similar genome sequence pairs and calculating pairwise ANI measures..."
	$vclust \
	align \
	-i $raw_files/all.fna  \
	-o $raw_files/ani.tsv \
	--filter $raw_files/fltr.txt \
	-t $SLURM_CPUS_PER_TASK \
	--out-gani 0.7 \
	--threads $SLURM_CPUS_PER_TASK \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/vclust.align.tsv

## creating final result file
	log "Creating final result file..."

	source $tools/biopython/myenv/bin/activate

	python $suppl_scripts/$pipeline.create_results.py \
	--input-ani $raw_files/ani.tsv \
	--input-taxonomy /veodata/03/databases/ictv/VMR_MSL39.v4_20241106.tsv \
	--output-tsv $raw_files/vclust_results.tsv \
	& my_pid=$!
	get_resource_stat $my_pid $resource_log/create_results.tsv

	deactivate

	rm -rf $raw_files/all.fna
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean
###############################################################################