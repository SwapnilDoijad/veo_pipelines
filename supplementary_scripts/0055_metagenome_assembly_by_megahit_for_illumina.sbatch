#!/bin/bash
#SBATCH --job-name 0055_metagenome_assembly_by_megahit_for_illumina
#SBATCH --partition=gpu
#SBATCH --output results/0055_metagenome_assembly_by_megahit_for_illumina/tmp/slurm/%j.out
#SBATCH --error results/0055_metagenome_assembly_by_megahit_for_illumina/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "SBATCH STARTED : 0055_metagenome_assembly_by_megahit_for_illumina -----------------------------------"
###############################################################################
## step-01: run megahit
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate megahit_v1.2.9
    cpus=$SLURM_CPUS_PER_TASK

    pipeline=0055_metagenome_assembly_by_megahit_for_illumina
    wd=results/$pipeline
    sublist=$wd/tmp/lists/ABC

    if [ -d results/0025_QC_of_paired-fastq_by_fastp ] ; then 
        fastq_file_path=results/0025_QC_of_paired-fastq_by_fastp/raw_files
        else 
        fastq_file_path=XYZ
    fi 
###############################################################################
    for i in $(cat $sublist); do
        if [ ! -d $wd/raw_files/$i ] ; then 
            log "STARTED : $pipeline for $i"

            megahit \
            -1 $fastq_file_path/$i*R1*.fastq.gz \
            -2 $fastq_file_path/$i*R2*.fastq.gz \
            -t $cpus \
             -m 0.9 \
            --out-prefix $i \
            --min-contig-len 500 \
            -o $wd/raw_files/$i

            cp $wd/raw_files/$i/$i.contigs.fa $wd/all_fasta/$i.fasta

            log "FINISHED : $pipeline for $i"
            else
            log "ALREADY FINISHED : $pipeline for $i"
        fi
    done

    echo -e "IDs\tnumber_of_contigs" > $wd/summary.tsv
    mkdir $wd/all_fasta > /dev/null 2>&1
    for i in $(cat $sublist); do
        if [ -f $wd/all_fasta/$i.fasta ] ; then
            number_of_contigs=$( grep -c ">" $wd/all_fasta/$i.fasta )
            echo -e "$i\t$number_of_contigs" >> $wd/summary.tsv
            else 
            echo -e "$i\tNA" >> $wd/summary.tsv
        fi
    done

###############################################################################
## step-02: run quast

        for i in $(cat $sublist); do
            if [ -f $wd/all_fasta/$i.fasta ] ; then 
                if [ ! -f $wd/raw_files/$i/quast/report.html ] ; then 
				    log "STARTED : $pipeline for $i : quast"

                    mkdir -p $wd/raw_files/$i/quast
                
                    python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
                    -o $wd/raw_files/$i/quast/ \
                    --silent \
                    $wd/all_fasta/$i.fasta

                    log "FINISHED : $pipeline for $i : quast"
                    else
                    log "ALREADY FINISHED : $pipeline for $i : quast"
                fi
                else
                log "ERROR : $pipeline for $i : contigs.fasta not found"
            fi 
        done

###############################################################################
## step-03: run metaquast

    for i in $(cat $sublist); do  
		if [ -f $wd/all_fasta/$i.fasta ] ; then 
			if [ ! -f $wd/raw_files/$i/metaquast/report.html ] ; then 
				log "metaquast for $i: running"

				mkdir -p $wd/raw_files/$i/metaquast/fasta

				python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent \
				-o $wd/raw_files/$i/quast/ \
				$wd/all_fasta/$i.fasta

				else
				log "metaquast for $i: already finished"
			fi
		fi
    done 
###############################################################################
## footer
    log "SBATCH ENDED : 0055_metagenome_assembly_by_megahit_for_illumina ----------------------"
###############################################################################

