#!/bin/bash
###############################################################################
#SBATCH --job-name 0992_calculate_abundance_from_degenerative_primer
#SBATCH --partition=interactive
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.combine_read_id
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.combine_read_id
###############################################################################

pipeline=0992_calculate_abundance_from_degenerative_primer
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
barcode_FR=ABC
barcode_RC=JKL
subsample=XYZ
mismatch=DEFGHI

    # if [ ! -f $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids_present_in_either_FR_RC.$mismatch.$subsample.txt ] ; then 

        num_of_barcode_FR=$( wc -l $raw_files/read_ids_extracted/$barcode_FR.$mismatch.tsv.tmp | awk '{print $1}' ) 
        num_of_barcode_RC=$( wc -l $raw_files/read_ids_extracted/$barcode_RC.$mismatch.tsv.tmp | awk '{print $1}' )

        ## duplicate read ids == read ids that are present in both FR and RC 
        duplicate_read_ids=$(cat $raw_files/read_ids_extracted/$barcode_FR.$mismatch.tsv.tmp \
        $raw_files/read_ids_extracted/$barcode_RC.$mismatch.tsv.tmp | sort | uniq -d | wc -l )

        cat $raw_files/read_ids_extracted/$barcode_FR.$mismatch.tsv.tmp \
        $raw_files/read_ids_extracted/$barcode_RC.$mismatch.tsv.tmp \
        | sort | uniq -d  > $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids_present_in_both_FR_RC.$mismatch.$subsample.txt

        non_duplicate_final_read_ids=$(cat $raw_files/read_ids_extracted/$barcode_FR.$mismatch.tsv.tmp \
        $raw_files/read_ids_extracted/$barcode_RC.$mismatch.tsv.tmp | sort | uniq | wc -l )

        cat $raw_files/read_ids_extracted/$barcode_FR.$mismatch.tsv.tmp \
        $raw_files/read_ids_extracted/$barcode_RC.$mismatch.tsv.tmp \
        | sort | uniq > $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids_present_in_either_FR_RC.$mismatch.$subsample.txt

        echo $barcode_FR $barcode_RC $mismatch $num_of_barcode_FR $num_of_barcode_RC $duplicate_read_ids $non_duplicate_final_read_ids \
        | tee -a $wd/tmp/read_ids.$mismatch.$subsample.tsv

    # fi