#!/bin/bash
###############################################################################
#SBATCH --job-name=blast
#SBATCH --partition=long,standard,gpu-veo
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.blast.out
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.blast.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=80
############################################################################### 
## read options for the inputfile
	pipeline=0992_calculate_abundance_from_degenerative_primer
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	database=$(grep my_database $parameters  | awk '{print $2}') ## need to read from parameter file

	subsample=my_subsample
	sample=my_sample
	mismatch=my_mismatch
	QC=my_qc

	log "STARTED : $pipeline"
	log "subsample: $subsample"
	log "sample: $sample"
	log "mismatch: $mismatch"
	log "QC: $QC"
	log "database: $database"
	
	if [ "$database" == "custom" ]; then 
		/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
		-db $raw_files/databases/query_sequence.fasta.db \
		-query $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta \
		-out $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv \
		-num_threads $SLURM_CPUS_PER_TASK \
		-subject_besthit \
		-max_target_seqs 500000 \
		-outfmt "6 qseqid sseqid qlen slen length mismatch qstart qend sstart send evalue bitscore qseq sseq" \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/$subsample.$sample.$mismatch.blast.silva.tsv 
			## notes:
				# @SWAPNIL: -max_target_seqs 500000 is used as custom database is used, which is a small database
					# although discription is 
						# -max_target_seqs does not return the top N best hits, just the first N found, which is then sorted 
						# However, -max_target_seqs is 50 as in custom dataset, there will not be more than 50 sequences
						# -max_hsps 1 is not used as need to force to get the best hit (despite of lower sequence similarities for Nanopore reads)

	elif [ "$database" != "custom" ]; then
		## silva database
		/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
		-task megablast \
		-db /veodata/03/databases/silva/v138.1/SILVA_138.1_SSUParc_tax_silva.2.fasta.db \
		-query $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta \
		-out $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv \
		-num_threads $SLURM_CPUS_PER_TASK \
		-subject_besthit \
		-max_target_seqs 500000 \
		-max_hsps 1 \
		-outfmt "6 qseqid sseqid qlen slen length mismatch qstart qend sstart send evalue bitscore qseq sseq" \
		& my_pid=$!
		get_resource_stat $my_pid $wd/tmp/resource_log/$subsample.$sample.$mismatch.blast.silva.tsv 

		## notes:
			# -max_target_seqs does not return the top N best hits, just the first N found, which is then sorted. W
			# However, -max_target_seqs is 100 as in silva database, there will be more than 100s of sequences for a 16s query 
			# MegaBLAST is optimized for highly similar sequences (e.g., >95% identity) and is FASTER than standard BLASTn.
			# Standard BLASTn is more sensitive and can detect more divergent sequences (e.g., <95% identity). BUT SLOWER
	fi

	wc -l $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv

	log "FINISHED: $pipeline"


	## discarded code 
		# -db $wd/databases/query_sequence.fasta.db \

