#!/bin/bash
###############################################################################
#SBATCH --job-name=extract_read_ids_if_two_pattern_present
#SBATCH --partition=interactive,standard,long
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.extract_read_ids_if_two_pattern_present.txt
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.extract_read_ids_if_two_pattern_present.txt
#SBATCH --mem=20G
#SBATCH --cpus-per-task=80
###############################################################################
## read options for the inputfile

pipeline=0992_calculate_abundance_from_degenerative_primer
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
barcode_FR=ABC
subsample=XYZ

	/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
	-db $wd/subsampled/all_combined.subsampled_"$subsample".fastq.fasta.db \
	-query $wd/tmp/barcode_tmp/$barcode_FR.fasta \
	-out $raw_files/read_ids_extracted/$barcode_FR.tsv \
	-num_threads $SLURM_CPUS_PER_TASK \
	-subject_besthit -max_target_seqs 500000 \
	-outfmt "6 qseqid sseqid qlen slen length pident nident mismatch gaps qcovs qstart qend sstart send evalue bitscore qseq sseq"

	sed -i '1i	qseqid	sseqid	qlen	slen	length	pident	nident	mismatch	gaps	qcovs	qstart	qend	sstart	send	evalue	bitscore	qseq	sseq' $raw_files/read_ids_extracted/$barcode_FR.tsv

	## notes:
		# @SWAPNIL: -max_target_seqs 500000 is used as custom database is used, which is a small database
			# although discription is 
				# -max_target_seqs does not return the top N best hits, just the first N found, which is then sorted 
				# However, -max_target_seqs is 50 as in custom dataset, there will not be more than 50 sequences
				# -max_hsps 1 is not 
