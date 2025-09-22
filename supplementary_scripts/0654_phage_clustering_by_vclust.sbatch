#!/bin/bash
#SBATCH --job-name=0654_phage_clustering_by_vclust
#SBATCH --partition=gpu-veo,gpu-test,gpu,standard,long
#SBATCH --output=results/0654_phage_clustering_by_vclust/tmp/slurm/%j.out
#SBATCH --error=results/0654_phage_clustering_by_vclust/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0654_phage_clustering_by_vclust
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
	ani=$( grep my_ani $parameters | awk '{print $2}' )
	figure=$( grep my_figure $parameters | awk '{print $2}' )
    list=list.$pipeline.txt
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: file and directory preparation
	log "combining all fasta"
	find "$fasta_directory" -name "*.fasta" -exec cat {} + | sed 's/:/_/g' | sed 's/,//g' > "$raw_files/all.fna"

	## Prefilter similar genome sequence pairs before conducting pairwise alignments.
	log "Prefiltering similar genome sequence pairs..."
	python3.9 /home/groups/VEO/tools/vclust/v1.2.7/vclust/vclust.py \
	prefilter \
	-i $raw_files/all.fna \
	-o $raw_files/fltr.txt \
	-t $SLURM_CPUS_PER_TASK  \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/vclust.prefilter.tsv

	## Align similar genome sequence pairs and calculate pairwise ANI measures.
	log "Aligning similar genome sequence pairs..."
	python3.9 /home/groups/VEO/tools/vclust/v1.0.0/vclust.py \
	align \
	-i $raw_files/all.fna  \
	-o $raw_files/ani.tsv \
	--filter $raw_files/fltr.txt \
	-t $SLURM_CPUS_PER_TASK \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/vclust.align.tsv

	## Cluster genome sequences based on given ANI measure and minimum threshold.
		## Dont care for the length-coverage (thus,fragment or complete phage belong to single phage in cluster)
	log "Clustering genome sequences..."
	python3.9 /home/groups/VEO/tools/vclust/v1.0.3/vclust.py \
	cluster \
	-i $raw_files/ani.tsv \
	-o $raw_files/clusters.tsv \
	--ids $raw_files/ani.ids.tsv \
	--metric ani \
	--ani $ani \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/vclust.cluster.tsv
	## -t is not available

	## Create a heatmap
	if [ figure == "yes" ]; then
		log "Creating heatmap..."
		source /home/groups/VEO/tools/biopython/myenv/bin/activate

		python3 $suppl_scripts/$pipeline.heatmap.py \
		-i $raw_files/clusters.tsv \
		-o $raw_files/clusters.tsv.heatmap.png

		# --color-by-checkv results/0072_QC_of_contigs_by_checkV/summary.tsv

		deactivate
	fi

###############################################################################
	log "FINISHED : $pipeline" && clean
###############################################################################
