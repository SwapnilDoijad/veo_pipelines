#!/bin/bash
#SBATCH --job-name=0663_phage_taxonomy_by_vista
#SBATCH --partition=standard,long
#SBATCH --output=results/0663_phage_taxonomy_by_vista/tmp/slurm/%j.out
#SBATCH --error=results/0663_phage_taxonomy_by_vista/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0663_phage_taxonomy_by_vista
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file=$( grep my_fasta_file $parameters | awk '{print $2}' )
	file_id=$( basename "$fasta_file" .fasta )

###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: BLAST
		log "STARTED: BLAST for $file_id -----------------------------"

			mkdir -p "$raw_files/blast/"

			setsid \
			$tools/blast/v2.14.0/bin/blastn \
			-query $fasta_file \
			-db "/veodata/03/databases/ncbi/v20230721/nt_viruses/nt_viruses" \
			-out "$raw_files/blast/$file_id.txt" \
			-outfmt "6 qseqid sseqid stitle pident length qlen slen staxids" \
			-max_target_seqs 1 \
			-num_threads $SLURM_CPUS_PER_TASK \
			& my_pid=$!
			pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
			accurate_log_usage_by_pgid "$pgid" $resource_log/vista.blast.tsv
		
		log "FINISHED: BLAST for $file_id -----------------------------"
###############################################################################
exit 


		cd /home/groups/VEO/tools/vista/for_ICTV_challenge_260628/ICTV-TaxonomyChallenge_VISTA

		# setsid \
		# singularity exec \
		# -B /vast:/vast \
		# vista_final.sif \
		# bash /opt/VISTA/Scripts/VISTA.sh \
		# -i /vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/data/combined_fasta/all59907.fasta \
		# -f Caudoviricetes \
		# -o /vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/VISTA_output \
		# -t 8 \
		# & my_pid=$!
		# pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		# accurate_log_usage_by_pgid "$pgid" $resource_log/VISTA_ALL.tsv

		setsid \
		singularity exec \
		-B /vast:/vast \
		vista_final.sif \
		bash /opt/VISTA/Scripts/VISTA.sh \
		-i /vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/data/combined_fasta/all59907.fasta \
		-f Caudoviricetes \
		-o /vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/results/0663_phage_taxonomy_by_vista/raw_files \
		-t 8 \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" /vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/results/0663_phage_taxonomy_by_vista/tmp/resource_log/VISTA_ALL.tsv	

###############################################################################
	log "FINISHED: $pipeline -----------------------------" # && clean
###############################################################################

