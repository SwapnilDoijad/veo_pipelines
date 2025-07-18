#!/bin/bash
###############################################################################
#SBATCH --job-name 01_0991_calculate_abundance_from_fastq
#SBATCH --partition=standard,long
#SBATCH --output results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.extract_read_ids_from_fastq_if_pattern_present
#SBATCH --error  results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.extract_read_ids_from_fastq_if_pattern_present
#SBATCH --mem=50G
###############################################################################
## read options for the inputfile
pipeline=0991_calculate_abundance_from_fastq
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
barcode=ABC
subsample=XYZ
sample_id=$(grep $barcode $wd/tmp/list_BarcodePrimers/list.barcodes.names.txt | awk '{print $2}')

    echo "runnig extract_read_ids_from_fastq_if_pattern_present for $barcode $sample_id FR"

    python3 $suppl_scripts/0991_extract_read_ids_from_fastq_if_pattern_present.py \
    -i $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
    -s $barcode \
    -o $raw_files/read_ids_extracted/list.$sample_id.$barcode.FR.read_ids.$subsample.txt

    wc -l $raw_files/read_ids_extracted/list.$sample_id.$barcode.FR.read_ids.$subsample.txt

    awk '{print $1}' $raw_files/read_ids_extracted/list.$sample_id.$barcode.FR.read_ids.$subsample.txt \
    | sed 's/@//g' > $raw_files/read_ids_extracted/list.$sample_id.$barcode.FR.read_ids.only.$subsample.txt

    echo "finished extract_read_ids_from_fastq_if_pattern_present for $barcode $sample_id FR"
