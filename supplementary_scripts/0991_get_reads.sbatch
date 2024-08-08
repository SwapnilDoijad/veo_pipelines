#!/bin/bash
###############################################################################
#SBATCH --job-name get_reads
#SBATCH --partition=interactive
#SBATCH --output results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.get_reads
#SBATCH --error results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.get_reads
###############################################################################
## read options for the inputfile

barcode=ABC
barcode_RC=JKL
subsample=XYZ

    echo "get_reads for $barcode and $barcode_RC for $subsample started" 
    
    python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_extract_reads_from_fastq_based_on_ids.py \
    -r results/0991_calculate_abundance_from_fastq/tmp/lists/list.$barcode.$barcode_RC.read_ids.$subsample.txt \
    -f results/0991_calculate_abundance_from_fastq/subsampled/all_combined.subsampled_$subsample.fastq \
    -o results/0991_calculate_abundance_from_fastq/files/$barcode.$barcode_RC.$subsample.fastq

    wc -l results/0991_calculate_abundance_from_fastq/files/$barcode.$barcode_RC.$subsample.fastq
    echo "get_reads for $barcode and $barcode_RC for $subsample finished"

