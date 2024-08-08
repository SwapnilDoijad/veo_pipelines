#!/bin/bash
###############################################################################
#SBATCH --job-name get_reads
#SBATCH --partition=short
#SBATCH --output results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.get_reads
#SBATCH --error results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.get_reads
###############################################################################
## read options for the inputfile
pipeline=0992_calculate_abundance_from_degenerative_primer
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

subsample=ABC
sample=JKL
mismatch=XYZ

        if [ ! -f $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq ] ; then
            log "STARTED : get_reads for $subsample $sample $mismatch" 

            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$subsample.$sample.0.fastq

            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.1.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$subsample.$sample.1.fastq

            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.2.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$subsample.$sample.2.fastq


            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.3.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$subsample.$sample.3.fastq
            
            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.01.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$subsample.$sample.01.fastq

            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.012.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$subsample.$sample.012.fastq

            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0123.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$subsample.$sample.0123.fastq


            reads_in_0_mismatch=$(count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.0.fastq )
            reads_in_1_mismatch=$(count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.1.fastq )
            reads_in_2_mismatch=$(count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.2.fastq )
            reads_in_3_mismatch=$(count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.3.fastq )
            reads_in_01_mismatch=$(count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.01.fastq )
            reads_in_012_mismatch=$(count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.012.fastq )
            reads_in_0123_mismatch=$(count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.0123.fastq )

            echo -e "$subsample\t$sample\t$reads_in_0_mismatch\t$reads_in_1_mismatch\t$reads_in_2_mismatch\t$reads_in_3_mismatch\t$reads_in_01_mismatch\t$reads_in_012_mismatch\t$reads_in_0123_mismatch" \
            >> $raw_files/reads_in_each_mismatch.txt

            log "FINISHED : get_reads for $subsample $sample $mismatch" 

            else
            log "ALREADY FINISHED : get_reads for $subsample $sample $mismatch"
        fi 

###############################################################################