#!/bin/bash
#SBATCH --job-name 0666_read_mapping_illumina_by_bbmap
#SBATCH --partition=standard
#SBATCH --output results/0666_read_mapping_illumina_by_bbmap/tmp/slurm/%j.out
#SBATCH --error results/0666_read_mapping_illumina_by_bbmap/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## 01: preparations
    echo "Hi Swpanil, do not parallelize this script. The reference is written in the same folder and thus if parallelized, it will overwrite the reference file and some samples will fail"
    echo "need to check if it is possible to write the reference file in a different folder"
    pipeline=0666_read_mapping_illumina_by_bbmap
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=tmp/parameters/$pipeline.txt

###############################################################################
    echo "#ID	Avg_fold	Length	Ref_GC	Covered_percent	Covered_bases	Plus_reads	Minus_reads	Read_GC	Median_fold	Std_Dev" > results/0666_read_mapping_illumina_by_bbmap/summary.txt

    while IFS= read -r line; do
        assembly_id=$( echo $line | awk '{print $1}' | awk -F'/' '{print $NF}' | sed 's/\.fasta//g')
        assembly_id_path=$( echo $line | awk '{print $1}' | xargs -I{} dirname {} )
        fwd_fastq_id=$( echo $line | awk  '{print $2}'| awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' )
        fwd_fastq_id_path=$( echo $line | awk '{print $2}' | xargs -I{} dirname {} )
        rev_fastq_id=$( echo $line | awk '{print $3}'| awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' )
        rev_fastq_id_path=$( echo $line | awk '{print $3}' | xargs -I{} dirname {} )

        echo "assembly_id: $assembly_id"
        echo "assembly_id_path: $assembly_id_path"
        echo "fwd_fastq_id: $fwd_fastq_id"
        echo "fwd_fastq_id_path: $fwd_fastq_id_path"
        echo "rev_fastq_id: $rev_fastq_id"
        echo  "rev_fastq_id_path: $rev_fastq_id_path"

        ## run bbmap
        if [ ! -f $wd/raw_files/$assembly_id/aln.sam.gz ]; then
            log "STARTED : $pipeline for $assembly_id.fasta + $fwd_fastq_id.fastq.gz + $rev_fastq_id.fastq.gz"

            /home/groups/VEO/tools/bbmap/v39.06/bbwrap.sh \
            ref=$assembly_id_path/$assembly_id.fasta \
            in=$fwd_fastq_id_path/$fwd_fastq_id.fastq.gz \
            in2=$rev_fastq_id_path/$rev_fastq_id.fastq.gz \
            out=$wd/raw_files/$assembly_id/aln.sam.gz \
            threads=40 

            /home/groups/VEO/tools/bbmap/v39.06/pileup.sh \
            in=$wd/raw_files/$assembly_id/aln.sam.gz \
            out=$wd/raw_files/$assembly_id/cov.txt

            awk 'NR>1 {print $0}' results/0666_read_mapping_illumina_by_bbmap/raw_files/$i/cov.txt \
            >> results/0666_read_mapping_illumina_by_bbmap/summary.txt

            log "FINISHED :  $pipeline for $assembly_id.fasta + $fwd_fastq_id.fastq.gz + $rev_fastq_id.fastq.gz"
            else
            echo "ALREADY FINISHED :  $pipeline for $assembly_id.fasta + $fwd_fastq_id.fastq.gz + $rev_fastq_id.fastq.gz"
        fi

        # ## sort file using samtools

        # /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
        # view -u -f4 $wd/raw_files/$assembly_id/aln.sam.gz \
        # | /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
        # bam2fq -s unmapped.se.fq - > unmapped.pe.fq

    done <  $sublist

    log "The run for sublist : $sublist is completed"

###############################################################################
## footer
###############################################################################