#!/bin/bash
###############################################################################
#SBATCH --job-name=0992_kraken2
#SBATCH --partition=interactive,long,standard,gpu-veo
#SBATCH --output=results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.kraken2
#SBATCH --error=results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.kraken2
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
pipeline=0992_calculate_abundance_from_degenerative_primer
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

subsample=my_subsample
sample=my_sample
mismatch=my_mismatch
QC=my_QC_value
	
	/home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
	--db /veodata/03/databases/kraken2/v20240605 \
	--output $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.out \
	--report $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report \
	--threads $SLURM_CPUS_PER_TASK \
	$raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/$subsample.$sample.$mismatch.kraken2.tsv 

	python3 /home/groups/VEO/tools/krakentools/v1.2/KrakenTools/kreport2krona.py \
	-r $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report \
	-o $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out.tmp \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/$subsample.$sample.$mismatch.kreport2krona.tsv 

	# kreport2krona generates lineage with 0 count, remove them
	awk '$1 != 0'  $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out.tmp \
	> $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out

	source /home/groups/VEO/tools/biopython/myenv/bin/activate
	python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fill_empty_field_of_bacterial_lineage.py \
	-i $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out \
	-o $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out.filled \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/$subsample.$sample.$mismatch.fill_empty_field_of_bacterial_lineage.tsv 
	deactivate

	awk '{print $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 "|" $8 "\t" $1}' $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out.filled \
	> $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out.filled.formatted
###############################################################################