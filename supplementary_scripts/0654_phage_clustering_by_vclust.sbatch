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
	cov=$( grep my_cov $parameters | awk '{print $2}' )
	UPGMA_Tree=$( grep my_UPGMA_Tree $parameters | awk '{print $2}' )
	figure=$( grep my_figure $parameters | awk '{print $2}' )
	version=$( grep my_vclust_version $parameters | awk '{print $2}' )
    list=list.$pipeline.txt
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: file and directory preparation
	log "combining all fasta"
	find "$fasta_directory" -name "*.fasta" -exec cat {} + | sed 's/:/_/g' | sed 's/,//g' > "$raw_files/all.fna"

	if [ $version = "1.2.7" ]; then

		## Prefilter similar genome sequence pairs before conducting pairwise alignments.
		log "Prefiltering similar genome sequence pairs..."
		python3.9 /home/groups/VEO/tools/vclust/v1.2.7/vclust/vclust.py \
		prefilter \
		-i ${raw_files}/all.fna \
		-o ${raw_files}/fltr.txt \
		-t ${SLURM_CPUS_PER_TASK} \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/vclust.prefilter.tsv

		## Align similar genome sequence pairs and calculate pairwise ANI measures.
		log "Aligning similar genome sequence pairs..."
		python3.9 /home/groups/VEO/tools/vclust/v1.2.7/vclust.py \
		align \
		-i ${raw_files}/all.fna  \
		-o ${raw_files}/ani.tsv \
		--filter ${raw_files}/fltr.txt \
		-t ${SLURM_CPUS_PER_TASK} \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/vclust.align.tsv

		## Cluster genome sequences based on given ANI measure and minimum threshold.
			## Dont care for the length-coverage (thus, fragment or complete phage belong to single phage in cluster)
		log "Clustering genome sequences..."
		python3.9 /home/groups/VEO/tools/vclust/v1.2.7/vclust.py \
		cluster \
		-i ${raw_files}/ani.tsv \
		-o ${raw_files}/clusters.tsv \
		--ids ${raw_files}/ani.ids.tsv \
		--metric tani \
		--ani $ani \
		--cov $cov \
		--algorithm single \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/vclust.cluster.tsv
		## -t is not available

		## need a ANI/distance matrix + UPGMA tree (Yes or No)
		if [ "$UPGMA_Tree" == "Yes" ]; then

			python3 ${suppl_scripts}/${pipeline}.representative.py \
			-i ${raw_files}/all.fna \
			-c ${raw_files}/clusters.tsv \
			-o ${raw_files}/clusters.tsv.representative.fasta

			# ANI: The number of identical nucleotides across local alignments divided by the total length of the alignments.
			# Global ANI (gANI): The number of identical nucleotides across local alignments divided by the length of the query/reference genome.
			# Total ANI (tANI): The number of identical nucleotides between query-reference and reference-query genomes divided by the sum length of both genomes. tANI is equivalent to the VIRIDIC's intergenomic similarity.
			## use tANI  
			mkdir -p ${raw_files}/tANI > /dev/null 2>&1
			source /home/groups/VEO/tools/biopython/myenv/bin/activate
			python ${suppl_scripts}/${pipeline}.matrix.py \
				-i ${raw_files}/ani.tsv \
				--ids ${raw_files}/clusters.tsv.representative.fasta.ids \
				--metric tani \
				-o ${raw_files}/tANI

			python ${suppl_scripts}/${pipeline}.UPGMA.py \
				-i ${raw_files}/tANI/tani_distance_matrix.tsv \
				-o ${raw_files}/tANI/tani_distance_matrix 
		fi

	elif [ $version = "1.3.1" ]; then

		source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
		conda activate vclust_v1.3.1
		## Prefilter similar genome sequence pairs before conducting pairwise alignments.
		log "Prefiltering similar genome sequence pairs..."
		vclust \
		prefilter \
		-i ${raw_files}/all.fna \
		-o ${raw_files}/fltr.txt \
		-t ${SLURM_CPUS_PER_TASK} \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/vclust.prefilter.tsv

		## Align similar genome sequence pairs and calculate pairwise ANI measures.
		log "Aligning similar genome sequence pairs..."
		vclust \
		align \
		-i ${raw_files}/all.fna  \
		-o ${raw_files}/ani.tsv \
		--filter ${raw_files}/fltr.txt \
		-t ${SLURM_CPUS_PER_TASK} \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/vclust.align.tsv

		## Cluster genome sequences based on given ANI measure and minimum threshold.
			## Dont care for the length-coverage (thus, fragment or complete phage belong to single phage in cluster)
		log "Clustering genome sequences..."
		vclust \
		cluster \
		-i ${raw_files}/ani.tsv \
		-o ${raw_files}/clusters.tsv \
		--ids ${raw_files}/ani.ids.tsv \
		--metric tani \
		--tani $cov \
		--ani $ani \
		--qcov $cov \
		--rcov $cov \
		-r \
		--algorithm single \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/vclust.cluster.tsv
		## -t is not available

		## seperate representative sequences ids for each cluster
		awk 'NR>1 {print $2}' ${raw_files}/clusters.tsv | sort | uniq \
		> ${raw_files}/clusters.tsv.representative.fasta.ids

		conda deactivate

		source /home/groups/VEO/tools/biopython/myenv/bin/activate 
		python ${suppl_scripts}/${pipeline}.split_fasta.py \
			-id ${raw_files}/clusters.tsv.representative.fasta.ids \
			-f ${raw_files}/all.fna \
			-o ${raw_files}/representative \
			--extension fasta

		if [ "$UPGMA_Tree" == "Yes" ]; then
			mkdir -p ${raw_files}/tANI > /dev/null 2>&1
			source /home/groups/VEO/tools/biopython/myenv/bin/activate
			python ${suppl_scripts}/${pipeline}.matrix.v1.3.3.py \
				-i ${raw_files}/ani.tsv \
				--ids ${raw_files}/clusters.tsv.representative.fasta.ids \
				--metric tani \
				-o ${raw_files}/tANI

			python ${suppl_scripts}/${pipeline}.UPGMA.py \
				-i ${raw_files}/tANI/tani_distance_matrix.tsv \
				-o ${raw_files}/tANI/tani_distance_matrix 
		fi 
	fi

###############################################################################
	## Create a heatmap
	if [ "$figure" == "Yes" ]; then
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

