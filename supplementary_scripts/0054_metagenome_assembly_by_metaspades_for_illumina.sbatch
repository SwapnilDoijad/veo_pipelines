#!/bin/bash
#SBATCH --job-name 0054_metagenome_assembly_by_metaspades_for_illumina
#SBATCH --partition=gpu
#SBATCH --output results/0054_metagenome_assembly_by_metaspades_for_illumina/tmp/slurm/%j.out
#SBATCH --error results/0054_metagenome_assembly_by_metaspades_for_illumina/tmp/slurm/%j.err
#SBATCH --mem=250G
#SBATCH --cpus-per-task=40
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "SBATCH STARTED : 0054_metagenome_assembly_by_metaspades_for_illumina -----------------------------------"
###############################################################################
## step-01: preparatoion
    pipeline=0054_metagenome_assembly_by_metaspades_for_illumina
    wd=results/$pipeline
    sublist=$wd/tmp/lists/ABC

    if [ -d results/0025_QC_of_paired-fastq_by_fastp ] ; then 
        fastq_file_path=results/0025_QC_of_paired-fastq_by_fastp/raw_files
        else 
        fastq_file_path=XYZ
    fi 

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/contigs.fasta ] || grep -q "== Error ==" $wd/raw_files/$i/spades.log ; then 
            log "STARTED : metaspades-assembler for $i"

            mkdir results/$pipeline/raw_files/$i

            python3 /home/groups/VEO/tools/SPAdes/v3.15.5/metaspades.py \
            -1 $fastq_file_path/$i*R1*.fastq.gz \
            -2 $fastq_file_path/$i*R2*.fastq.gz \
            -t $SLURM_CPUS_PER_TASK \
            -m 500 \
            -o $wd/raw_files/$i

            log "FINISHED : metaspades-assembler for $i"
            else
            log "ALREADY FINISHED : metaspades-assembler for $i"
        fi
    done

    echo -e "IDs\tnumber_of_contigs" > $wd/summary.tsv
    mkdir $wd/all_fasta > /dev/null 2>&1
    for i in $(cat $sublist); do
        if [ -f $wd/raw_files/$i/contigs.fasta ] && [ ! -f $wd/all_fasta/$i.contigs.fasta ] ; then
            cp $wd/raw_files/$i/contigs.fasta $wd/all_fasta/$i.contigs.fasta

            number_of_contigs=$(grep -c ">" $wd/raw_files/$i/contigs.fasta)
            echo $number_of_contigs >> $wd/summary.tsv
            else 
            echo "$i NA" >> $wd/summary.tsv
        fi
    done

###############################################################################
## step-02: run quast

        for i in $(cat $sublist); do
            if [ -f $wd/raw_files/$i/contigs.fasta ] ; then 
                if [ ! -f $wd/raw_files/$i/quast/report.html ] ; then 
				    log "STARTED : $pipeline for $i : quast"

                    mkdir -p $wd/raw_files/$i/quast
                
                    python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
                    -o $wd/raw_files/$i/quast/ \
                    -t 40 \
                    --silent \
                    $wd/raw_files/$i/contigs.fasta

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
		if [ -f $wd/raw_files/$i/contigs.fasta ] ; then 
			if [ ! -f $wd/raw_files/$i/metaquast/report.html ] ; then 
                log "STARTED : $pipeline for $i : metaquast"

				mkdir -p $wd/raw_files/$i/metaquast/fasta

				python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent \
                -t 40 \
				-o $wd/raw_files/$i/metaquast/ \
				$wd/raw_files/$i/contigs.fasta 

                log "FINISHED : $pipeline for $i : metaquast"
                else
                log "ALREADY FINISHED : $pipeline for $i : metaquast"
			fi
            log "ERROR : $pipeline for $i : contigs.fasta not found"
		fi
    done 

###############################################################################
## footer
    log "SBATCH ENDED : 0054_metagenome_assembly_by_metaspades_for_illumina ----------------------"
###############################################################################
