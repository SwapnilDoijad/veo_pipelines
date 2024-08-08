#!/bin/bash
###############################################################################
#SBATCH --job-name blast
#SBATCH --partition=long
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.blast
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.blast
#SBATCH --mem=20G
#SBATCH --cpus-per-task=24
###############################################################################
## read options for the inputfile
	pipeline=0992_calculate_abundance_from_degenerative_primer
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	subsample=my_subsample
	sample=my_sample
	mismatch=my_mismatch
	QC=my_qc

	## blast each read against each query seqeunce 

	log "STARTED : $subsample $sample $mismtach $QC"
	
	/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
	-db /work/groups/VEO/databases/silva/v138.1/SILVA_138.1_SSUParc_tax_silva.2.fasta.db \
	-query $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta \
	-out $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv \
	-num_threads 24 \
	-subject_besthit -max_target_seqs 1 -outfmt "6 qseqid sseqid qlen slen length mismatch qstart qend sstart send evalue bitscore qseq sseq"

	wc -l $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv

	log "FINISHED: $subsample $sample $mismtach $QC"


	## discarded code 
		# -db $wd/databases/query_sequence.fasta.db \