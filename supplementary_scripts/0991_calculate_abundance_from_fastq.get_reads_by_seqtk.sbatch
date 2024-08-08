#!/bin/bash
###############################################################################
#SBATCH --job-name=02_0991_calculate_abundance_from_fastq
#SBATCH --partition=interactive
#SBATCH --output=results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.get_reads
#SBATCH --error=results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.get_reads
###############################################################################
## read options for the inputfile
pipeline=0991_calculate_abundance_from_fastq
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

barcode_FR=ABC
barcode_RC=DEF
subsample=JKL
QC=my_QC_value

        if [ ! -f $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.$subsample.fastq ] ; then
            log "STARTED : get_reads for $subsample" 

            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk subseq \
            $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt \
            > $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.$subsample.fastq

            number_of_reads=$( count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.$subsample.fastq )

            echo -e "$subsample\t$sample\t$number_of_reads" \
            >> $raw_files/reads_ids.txt

            log "FINISHED : get_reads for $subsample" 

            else
            log "ALREADY FINISHED : get_reads for $subsample"
        fi 

###############################################################################
