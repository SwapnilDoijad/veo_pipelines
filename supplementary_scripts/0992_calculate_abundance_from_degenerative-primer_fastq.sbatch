#!/bin/bash
###############################################################################
#SBATCH --job-name blast
#SBATCH --partition=standard
#SBATCH --output results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.blast
#SBATCH --error results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.blast
#SBATCH --mem=80G
#SBATCH --cpus-per-task=80
###############################################################################
## read options for the inputfile

barcode=ABC
barcode_RC=JKL
subsample=XYZ

	# blast each read against each  seqeunce 

	echo "$barcode && $barcode_RC for $subsample"
	
	/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
	-db /work/groups/VEO/databases/silva/v138.1/SILVA_138.1_SSURef_NR99_tax_silva.2.fasta.db \
	-query results/0991_calculate_abundance_from_fastq/files/$barcode.$barcode_RC.$QC.fastq.$subsample.fasta \
	-out results/0991_calculate_abundance_from_fastq/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.$subsample.tsv \
	-num_threads 80 -subject_besthit -max_target_seqs 1 -outfmt "6 qseqid sseqid qlen slen length mismatch qstart qend sstart send evalue bitscore qseq sseq"

	wc -l results/0991_calculate_abundance_from_fastq/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.$subsample.tsv

	echo "finished: $barcode && $barcode_RC for $subsample "

exit
