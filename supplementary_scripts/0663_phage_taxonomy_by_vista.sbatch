#!/bin/bash
#SBATCH --job-name=0663_phage_taxonomy_by_vista
#SBATCH --partition=standard,long
#SBATCH --output=results/0663_phage_taxonomy_by_vista/tmp/slurm/%j.out
#SBATCH --error=results/0663_phage_taxonomy_by_vista/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0663_phage_taxonomy_by_vista
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file=$( grep my_fasta_file $parameters | awk '{print $2}' )
	file_id=$( basename "$fasta_file" .fasta )

	vista="/home/groups/VEO/tools/vista/for_ICTV_challenge/ICTV-TaxonomyChallenge_VISTA/Pipeline_scripts/"
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
## step-02: VISTA taxonomy assignment
	log "STARTED: VISTA taxonomy assignment for $file_id -----------------------------"

		setsid \
		python3 $vista/BLAST_txt_to_csv.py \
		-i "$raw_files/blast" \
		-o "$raw_files/blast_out.csv"  \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/vista.BLAST_txt_to_csv.tsv

	log "FINISHED: VISTA taxonomy assignment for $file_id -----------------------------"
###############################################################################
## step-03: VISTA taxonomy assignment filtering and classification
	log "STARTED: VISTA taxonomy filtering and classification for $file_id -----------------------------"

			## author suggested 80% alingment cutoff, but we get only ~15000 (also there is an issue with the comma in stitle field) 
			## there is issue with the filtering !!
			## I am running without cutoffs 

		setsid \
		awk -F',' 'BEGIN{FPAT="([^,]*)|(\"[^\"]+\")"} ($7>0 && $5 >= 0.8 * $7) {print}' \
		"$raw_files/blast_out.csv" \
		> "$raw_files/blast_filtered.tsv" \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/vista.awk.blast_filtered.tsv

	log "FINISHED: VISTA taxonomy filtering and classification for $file_id -----------------------------"
###############################################################################
## step-04: VISTA taxonomy assignment - family name extraction and fasta classification
	log "STARTED: VISTA taxonomy family name extraction and fasta classification for $file_id ----------------"

		source /home/groups/VEO/tools/biopython/myenv/bin/activate
		setsid \
		python $vista/Get_family_name.py \
		-i $raw_files/blast_out.csv \
		-o $raw_files/family_names.tsv  \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/vista.Get_family_name.tsv
		deactivate

	log "FINISHED: VISTA taxonomy family name extraction and fasta classification for $file_id ----------------"
###############################################################################
## step-05: VISTA taxonomy assignment - final classification
	log "STARTED: VISTA taxonomy final classification for $file_id -----------------------------"

		mkdir -p "$raw_files/classify_fasta/"

		setsid \
		$vista/Classify_fasta.sh \
		-d $raw_files/family_names.tsv \
		-i $raw_files/blast \
		-o $raw_files/classify_fasta \
		& my_pid=$!
		pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
		accurate_log_usage_by_pgid "$pgid" $resource_log/vista.Classify_fasta.tsv

	log "FINISHED: VISTA taxonomy final classification for $file_id -----------------------------"

###############################################################################
	log "FINISHED: $pipeline -----------------------------" # && clean
###############################################################################

