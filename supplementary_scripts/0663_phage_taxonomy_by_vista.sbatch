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
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	sublist=$wd/tmp/lists/ABC

	vista="/home/groups/VEO/tools/vista/for_ICTV_challenge/ICTV-TaxonomyChallenge_VISTA/Pipeline_scripts/"
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: BLAST

	for i in $(cat $sublist); do
		log "STARTED: blast : $i"

		# mkdir -p "$raw_files/blast/"
		# $tools/blast/v2.14.0/bin/blastn \
		# -query $fasta_directory/$i.fasta \
		# -db "/veodata/03/databases/ncbi/v20230721/nt_viruses/nt_viruses" \
		# -out "$raw_files/blast/$i.txt" \
		# -outfmt "6 qseqid sseqid stitle pident length qlen slen staxids" \
		# -max_target_seqs 1 \
		# -num_threads $SLURM_CPUS_PER_TASK \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.vista.blast.tsv

		## 2025-08-28 09:00:12 @Swapnil, shift above command to sbatch and 
		## wait command needs to be added, as below
		## command need to run only once for all

		# python3 $vista/BLAST_txt_to_csv.py \
		# -i "$raw_files/blast" \
		# -o "$raw_files/blast_out.csv"  \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.vista.BLAST_txt_to_csv.tsv

			## author suggested 80% alingment cutoff, but we get only ~15000 (also there is an issue with the comma in stitle field) 
			## there is issue with the filtering !!
			## I am running without cutoffs 

				# awk -F',' 'BEGIN{FPAT="([^,]*)|(\"[^\"]+\")"} ($7>0 && $5 >= 0.8 * $7) {print}' \
				# "$raw_files/blast_out.csv" \
				# > "$raw_files/blast_filtered.tsv" \
				# & my_pid=$!
				# get_resource_stat $my_pid $resource_log/$i.vista.awk.blast_filtered.tsv

			source /home/groups/VEO/tools/biopython/myenv/bin/activate
			python $vista/Get_family_name.py \
			-i $raw_files/blast_out.csv \
			-o $raw_files/family_names.tsv  \
			& my_pid=$!
			get_resource_stat $my_pid $resource_log/$i.vista.Get_family_name.tsv
			deactivae

	done

###############################################################################
	log "FINISHED: $pipeline -----------------------------" # && clean
###############################################################################

