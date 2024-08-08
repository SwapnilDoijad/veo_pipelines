#!/bin/bash
###############################################################################
#SBATCH --job-name extract_read_ids_if_two_pattern_present
#SBATCH --partition=interactive
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.extract_read_ids_if_two_pattern_present.txt
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.extract_read_ids_if_two_pattern_present.txt
###############################################################################
## read options for the inputfile

pipeline=0992_calculate_abundance_from_degenerative_primer
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

barcode_FR=ABCDEF
barcode_RC=GHIJKL
subsample=XYZ 

    echo "runnig extract_read_ids_if_pattern_present for $barcode_FR $barcode_RC"

    /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk seq \
    $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
    | grep -B1 -A2 "$barcode_FR" | grep -B1 -A2 "$barcode_RC" | grep "^@" \
    > $wd/tmp/lists/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt

    wc -l $wd/tmp/lists/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt

    awk '{print $1}' $wd/tmp/lists/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt \
    | sed 's/@//g' > $wd/tmp/lists/list.$barcode_FR.$barcode_RC.read_ids.only.$subsample.txt

    echo "finished extract_read-ids_if_pattern_present for $barcode_FR $barcode_RC"