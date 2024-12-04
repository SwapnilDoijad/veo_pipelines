#!/bin/bash
#SBATCH --job-name 0667_read_mapping_nanopore_by_bbmap
#SBATCH --partition=short
#SBATCH --output results/0667_read_mapping_nanopore_by_bbmap/tmp/slurm/%j.out
#SBATCH --error results/0667_read_mapping_nanopore_by_bbmap/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=80
###############################################################################
## 01: preparations
    echo "Hi Swpanil, do not parallelize this script. The reference is written in the same folder and thus if parallelized, it will overwrite the reference file and some samples will fail"
    echo "need to check if it is possible to write the reference file in a different folder"
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0667_read_mapping_nanopore_by_bbmap
    wd=results/$pipeline
    raw_files=$wd/raw_files
    sublist=$wd/tmp/lists/ABC

###############################################################################
    while IFS= read -r line; do
        assembly_id=$( echo $line | awk '{print $1}' | awk -F'/' '{print $NF}' | sed 's/\.fasta//g')
        assembly_id_path=$( echo $line | awk '{print $1}' | xargs -I{} dirname {} )
        fastq_id=$( echo $line | awk  '{print $2}'| awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' )
        fastq_id_path=$( echo $line | awk '{print $2}' | xargs -I{} dirname {} )
        
        if [ ! -f $fastq_id_path/$fastq_id.fastq ] ; then 
        if [ -f $fastq_id_path/$fastq_id.fastq.gz ] ; then 
            gunzip -c $fastq_id_path/$fastq_id.fastq.gz > $fastq_id_path/$fastq_id.fastq
        fi
        fi

        ## convert fastq to fasta
        if [ ! -f $fastq_id_path/$fastq_id.fasta ] ; then 
        python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastq2fasta.multiprocessing.py \
        -i $fastq_id_path/$fastq_id.fastq \
        -o $fastq_id_path/$fastq_id.fasta
        fi

        ## run bbmap
        if [ ! -f $wd/raw_files/$assembly_id/aln.sam.gz ]; then
            log "STARTED : $pipeline for $assembly_id.fasta + $fastq_id.fastq.gz"
            mkdir -p $raw_files/$assembly_id

            /home/groups/VEO/tools/bbmap/v39.06/mapPacBio.sh \
            ref=$assembly_id_path/$assembly_id.fasta \
            in=$fastq_id_path/$fastq_id.fasta \
            fastareadlen=6000 \
            out=$wd/raw_files/$assembly_id/aln.sam.gz \
            threads=$SLURM_CPUS_PER_TASK 

            /home/groups/VEO/tools/bbmap/v39.06/pileup.sh \
            in=$wd/raw_files/$assembly_id/aln.sam.gz \
            out=$wd/raw_files/$assembly_id/cov.txt

            log "FINISHED :  $pipeline for $assembly_id.fasta + $fastq_id.fastq.gz"
            else
            echo "ALREADY FINISHED :  $pipeline for $assembly_id.fasta + $fastq_id.fastq.gz"
        fi

        # ## sort file using samtools
        # /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
        # view -u -f4 $wd/raw_files/$assembly_id/aln.sam.gz \
        # | /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
        # bam2fq -s unmapped.se.fq - > unmapped.pe.fq


        # /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
        # sort -@ 10 -l 9 -m 5000M \
        # -o $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
        # $wd/raw_files/sam_files/$assembly_id.$fastq_id.sam

        # ## get summary of sorted .bam file using samtools
        # /home/groups/VEO/tools/samtools/v1.17/bin/samtools flagstat \
        # $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
        # > $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt

        # echo "--------------------------------------------------------------------------------" >> $wd/summary.txt
        # echo $assembly_id $fastq_id >> $wd/summary.txt
        # cat $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt \
        # >> $wd/summary.txt
        # echo "--------------------------------------------------------------------------------" >> $wd/summary.txt

    done <  $wd/tmp/lists/ABC

    log "The run for sublist : $sublist is completed"

###############################################################################
## footer
###############################################################################