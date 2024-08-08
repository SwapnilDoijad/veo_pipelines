#!/bin/bash
###############################################################################
#SBATCH --job-name=03_0991_calculate_abundance_from_fastq
#SBATCH --partition=interactive
#SBATCH --output results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.blast
#SBATCH --error results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.blast
#SBATCH --mem=20G
#SBATCH --cpus-per-task=24
###############################################################################
## read options for the inputfile
	pipeline=0991_calculate_abundance_from_fastq
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	barcode_FR=ABC
	barcode_RC=JKL
	subsample=XYZ
	QC=DEF
	database_parameter=$( grep my_database $parameters | awk '{print $2}' )

	# blast each read against each query seqeunce 

	log "STARTED : $barcode_FR && $barcode_RC for brady for $subsample"
	
	if [[ $database_parameter == "silva" ]] ; then 
		database="/work/groups/VEO/databases/silva/v138.1/SILVA_138.1_SSUParc_tax_silva.2.fasta.db"
	elif [[ $database_parameter == "query_sequences" ]] ; then 
		database="$wd/databases/query_sequence.fasta.db"
	else
		echo "ERROR: database not found (database_parameter=$database_parameter)"
		exit 1
	fi
	
	/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
	-db $database \
	-query $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta \
	-out $raw_files/blast_results/$barcode_FR.$barcode_RC.$QC.fastq.fasta.$subsample.tsv \
	-num_threads 24 \
	-subject_besthit -max_target_seqs 1 -outfmt "6 qseqid sseqid qlen slen length mismatch qstart qend sstart send evalue bitscore qseq sseq"

	wc -l $raw_files/blast_results/$barcode_FR.$barcode_RC.$QC.fastq.fasta.$subsample.tsv

	log "FINISHED: $barcode_FR && $barcode_RC for $subsample "

