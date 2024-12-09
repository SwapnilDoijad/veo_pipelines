#!/bin/bash
###############################################################################
#SBATCH --job-name=04_demultiplex_to_combinedBarcodeFastq
#SBATCH --partition=interactive
#SBATCH --output=results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.out.04_demultiplex_to_combinedBarcodeFastq
#SBATCH --error=results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.err.04_demultiplex_to_combinedBarcodeFastq
#SBATCH --job-name=0008_demultiplexing_nanopore_basecalling_by_guppy_gpu
###############################################################################
## read options for the inputfile
    pipeline=0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	if [ ! -f $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw_gzip/my_barcode.fastq.gz ] ; then 
		gzip --stdout $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw/my_barcode.fastq \
		> $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw_gzip/my_barcode.fastq.gz
	fi 

	if [ ! -f $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10_gzip/my_barcode.10.fastq.gz ] ; then
		gzip --stdout $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10/my_barcode.10.fastq \
		> $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10_gzip/my_barcode.10.fastq.gz
	fi
###############################################################################