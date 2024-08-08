#!/bin/bash
###############################################################################
#SBATCH --job-name 0992_calculate_abundance_from_degenerative_primer
#SBATCH --partition=short
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.filtering_and_trimming_barcodePrimer_sequences
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.filtering_and_trimming_barcodePrimer_sequences
#SBATCH --cpus-per-task=10
#SBATCH --mem=20G
###############################################################################

pipeline=0992_calculate_abundance_from_degenerative_primer
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

subsample=my_subsample
sample=my_sample
mismatch=my_mismatch

source /home/groups/VEO/tools/biopython/myenv/bin/activate
python $suppl_scripts/$pipeline.filtering_and_trimming_barcodePrimer_sequences.py \
-1 $wd/tmp/list_BarcodePrimers/samples/$sample/list.barcodes_all.FR.txt \
-2 $wd/tmp/list_BarcodePrimers/samples/$sample/list.barcodes_all.RC.txt \
-f $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq \
-o $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.filtered \
-l $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.length_report.txt

###############################################################################