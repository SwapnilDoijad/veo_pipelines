#!/bin/bash
###############################################################################
#SBATCH --job-name=03_0991_calculate_abundance_from_fastq
#SBATCH --partition=short
#SBATCH --output=results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.get_reads
#SBATCH --error=results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.get_reads
#SBATCH --cpus-per-task=40
#SBATCH --mem=50G
###############################################################################
pipeline=0991_calculate_abundance_from_fastq
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

barcode_FR=my_barcode_FR
barcode_RC=my_barcode_RC
subsample=my_subsample
QC=my_QC_value

run_id=$( pwd | awk -F'/' '{print $NF}' | awk -F'_' '{print $NF}')
sample_id_tmp=$(grep $barcode_FR.$barcode_RC $wd/tmp/list_BarcodePrimers/list.barcodes.names.txt | awk '{print $2}')
sample_id=$(grep -w $sample_id_tmp tmp/parameters/0991_calculate_abundance_from_fastq.my_barcode.txt | awk '{print $1}' )

	/home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
	--db /work/groups/VEO/databases/kraken2/v20180901 \
	--output $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.out \
	--report $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.report \
	--threads 40 \
	$raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta

	python3 /home/groups/VEO/tools/krakentools/v1.2/KrakenTools/kreport2krona.py \
	-r $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.report \
	-o $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.report.out 

	source /home/groups/VEO/tools/biopython/myenv/bin/activate
	python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fill_empty_field_of_bacterial_lineage.py \
	-i $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.report.out \
	-o $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.report.out.filled
	deactivate

	awk '{print $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 "|" $8 "\t" $1}' $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.report.out.filled \
	> $raw_files/kraken2/hits/"$run_id"_"$sample_id".$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta.report.out.filled.formatted
###############################################################################