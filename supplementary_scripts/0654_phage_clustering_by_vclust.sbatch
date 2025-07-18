#!/bin/bash
#SBATCH --job-name=0654_phage_clustering_by_vclust
#SBATCH --partition=short,standard,long,interactive,gpu-test,gpu
#SBATCH --output=results/0654_phage_clustering_by_vclust/tmp/slurm/%j.out
#SBATCH --error=results/0654_phage_clustering_by_vclust/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0654_phage_clustering_by_vclust
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -----------------------------"

	fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
	figure=$( grep my_figure $parameters | awk '{print $2}' )
    list=list.$pipeline.txt
###############################################################################
## step-01: file and directory preparation
	cat	$fasta_directory/*.fasta | sed 's/:/_/g' | sed 's/,//g' > $raw_files/all.fna

	## Prefilter similar genome sequence pairs before conducting pairwise alignments.
	python3.9 /home/groups/VEO/tools/vclust/v1.2.7/vclust/vclust.py \
	prefilter \
	-i $raw_files/all.fna \
	-o $raw_files/fltr.txt \
	-t $SLURM_CPUS_PER_TASK 

	## Align similar genome sequence pairs and calculate pairwise ANI measures.
	python3.9 /home/groups/VEO/tools/vclust/v1.0.0/vclust.py \
	align \
	-i $raw_files/all.fna  \
	-o $raw_files/ani.tsv \
	--filter $raw_files/fltr.txt \
	-t $SLURM_CPUS_PER_TASK

	## Cluster genome sequences based on given ANI measure and minimum threshold.
	python3.9 /home/groups/VEO/tools/vclust/v1.0.3/vclust.py \
	cluster \
	-i $raw_files/ani.tsv \
	-o $raw_files/clusters.tsv \
	--ids $raw_files/ani.ids.tsv \
	--metric ani \
	--ani 0.95 
	## -t is not available 


	## Create a heatmap
	if [ figure == "yes" ]; then
		source /home/groups/VEO/tools/biopython/myenv/bin/activate

		python3 $plots/$pipeline.heatmap.py \
		-i $raw_files/clusters.tsv \
		-o $raw_files/clusters.tsv.heatmap.png

		# --color-by-checkv results/0072_QC_of_contigs_by_checkV/summary.tsv

		deactivate
	fi



###############################################################################