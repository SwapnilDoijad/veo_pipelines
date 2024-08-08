#!/bin/bash
###############################################################################
#SBATCH --job-name extract_read_ids_if_two_pattern_present
#SBATCH --partition=interactive
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.extract_read_ids_if_two_pattern_present.txt
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.extract_read_ids_if_two_pattern_present.txt
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
	-subject_besthit -max_target_seqs 500000 \
	-outfmt "6 qseqid sseqid qlen slen length pident nident mismatch gaps qcovs qstart qend sstart send evalue bitscore qseq sseq"

	sed -i '1i	qseqid	sseqid	qlen	slen	length	pident	nident	mismatch	gaps	qcovs	qstart	qend	sstart	send	evalue	bitscore	qseq	sseq' $raw_files/read_ids_extracted/$barcode_FR.tsv
