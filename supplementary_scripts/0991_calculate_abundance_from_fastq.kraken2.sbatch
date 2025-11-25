#!/bin/bash
###############################################################################
#SBATCH --job-name=03_0991_calculate_abundance_from_fastq
#SBATCH --partition=standard,long
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
sample_id=my_sample
mismatch=my_mismatch
QC=my_QC_value
run_id=$( pwd | awk -F'/' '{print $NF}' | awk -F'_' '{print $NF}')
database=$( grep my_database $parameters | awk $fastq_path '{print $2}' )

if [ "$database" = "silva" ]; then
		database_path=/veodata/03/databases/kraken2/silva_16s_138
	elif [ "$database" = "kraken2" ]; then
		database_path=/veodata/03/databases/kraken2/v20240605
	else
		log "invalid database name: $database"
fi
	
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate perl_v5.32.1

	/home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
	--db $database_path \
	--output $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.out \
	--report $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.report \
	--threads 40 \
	$raw_files/read_ids_extracted_fastq/$sample_id.$QC.$subsample.fasta

	conda deactivate

	python3 /home/groups/VEO/tools/krakentools/v1.2/KrakenTools/kreport2krona.py \
	-r $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.report \
	-o $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.report.out 

	source /home/groups/VEO/tools/biopython/myenv/bin/activate
	python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fill_empty_field_of_bacterial_lineage.py \
	-i $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.report.out \
	-o $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.report.out.filled
	deactivate

	awk '{print $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 "|" $8 "\t" $1}' $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.report.out.filled \
	> $raw_files/kraken2/hits/"$run_id"_"$sample_id".$sample_id.$QC.$subsample.fasta.report.out.filled.formatted
###############################################################################