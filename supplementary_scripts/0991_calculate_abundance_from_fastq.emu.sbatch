#!/bin/bash
###############################################################################
#SBATCH --job-name=0991_emu
#SBATCH --partition=long,standard,gpu-veo,gpu-test,gpu
#SBATCH --output=results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.emu
#SBATCH --error=results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.emu
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
pipeline=0991_calculate_abundance_from_fastq
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

subsample=my_subsample
sample=my_sample
mismatch=my_mismatch
QC=my_qc_value
database=$(grep my_database $parameters  | awk '{print $2}')

if [ "$database" = "silva" ]; then
		database_path=/veodata/03/databases/emu/v240807_silva
	elif [ "$database" = "emu" ]; then
		database_path=/veodata/02/databases/emu/v240807
	else
		log "invalid database name: $database"
fi
###############################################################################
## run emu tool

	log "STARTED: emu abundance calculation for $sample.$QC.$subsample with $mismatch mismatches"
	
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate emu_v3.4.5 

	emu abundance \
	--type map-ont \
	--db $database_path \
	--output-dir $raw_files/emu/$database \
	--output-basename $sample.$QC.$subsample \
	--keep-counts \
	--keep-read-assignments \
	--threads $SLURM_CPUS_PER_TASK \
	$raw_files/read_ids_extracted_fastq/$sample.$QC.$subsample.fasta \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/$subsample.$sample.$mismatch.emu.$database.tsv

	sed -i 's/ /_/g' $raw_files/emu/$database/$sample.$QC.${subsample}_rel-abundance.tsv
	sed -i 's/\t\t/\tunassigned\t/g' $raw_files/emu/$database/$sample.$QC.${subsample}_rel-abundance.tsv

	mv $raw_files/emu/$database/$sample.$QC.${subsample}_read-assignment-distributions.tsv \
	$raw_files/emu/distribution/

	log "FINISHED: emu abundance calculation for $sample.$QC.$subsample with $mismatch mismatches"
	
###############################################################################