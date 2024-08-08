#!/bin/bash
###############################################################################
#SBATCH --job-name blast_rhizo
#SBATCH --partition=long
#SBATCH --output results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.blast_rhizo
#SBATCH --error results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.blast_rhizo
#SBATCH --mem=20G
###############################################################################
## read options for the inputfile

barcode=ABC
barcode_RC=JKL
subsample=XYZ

# blast each read against each rhizo seqeunce 

	echo "$barcode && $barcode_RC for rhizo for $subsample"

	/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
	-db /home/xa73pav/projects/p_nanopore_third_run_24h/tmp/databases/query_rhizo.fasta.db \
	-query results/0991_calculate_abundance_from_fastq//files/$barcode.$barcode_RC.10.fastq.$subsample.fasta \
	-out results/0991_calculate_abundance_from_fastq/blast_results/$barcode.$barcode_RC.10.fastq.fasta.rhizo.$subsample.tsv \
	-subject_besthit -max_target_seqs 50000 -outfmt "6 qseqid sseqid qlen slen length mismatch qstart qend sstart send evalue bitscore qseq sseq"

	wc -l results/0991_calculate_abundance_from_fastq/blast_results/$barcode.$barcode_RC.10.fastq.fasta.rhizo.$subsample.tsv

	echo "finished: $barcode && $barcode_RC for rhizo for $subsample"