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
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: BLAST

	for i in $(cat $sublist); do
		log "STARTED: blast : $i"

		$tools/blast/v2.14.0/bin/blastn \
		-query $fasta_directory/$i.fasta \
		-db "/veodata/03/databases/ncbi/v20230721/nt_viruses/nt_viruses" \
		-out "$raw_files/blast_out" \
		-outfmt "6 qseqid sseqid stitle pident length qlen slen staxids" \
		-max_target_seqs 1 \
		-num_threads $SLURM_CPUS_PER_TASK \
		& my_pid=$!
		get_resource_stat $my_pid $resource_log/vista.blast.tsv
	done

###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean
###############################################################################

