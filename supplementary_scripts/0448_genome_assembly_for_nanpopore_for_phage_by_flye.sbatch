#!/bin/bash
#SBATCH --job-name 0448_genome_assembly_for_nanpopore_for_phage_by_flye
#SBATCH --partition=short
#SBATCH --output results/0448_genome_assembly_for_nanpopore_for_phage_by_flye/tmp/slurm/%j.out.0048_genome_assembly_by_fly
#SBATCH --error results/0448_genome_assembly_for_nanpopore_for_phage_by_flye/tmp/slurm/%j.err.0048_genome_assembly_by_fly
#SBATCH --mem=50G
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0448_genome_assembly_for_nanpopore_for_phage_by_flye
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    conda activate flye_v2.9.2
    sublist=$wd/tmp/lists/ABC
############################################################################### 
log "STARTED SBATCH : $pipeline : $sublist"
############################################################################### 
## step-01: run flye-assembler
    log "STARTED : flye-assembler step"

    for i in $(cat $sublist); do
        if [ ! -d $raw_files/$i ]; then 
            log "STARTED : $i : flye"

            flye --meta -t $SLURM_CPUS_PER_TASK \
            --nano-raw $data_directory_fastq_path/$i.fastq.gz \
            --out-dir $raw_files/$i ;

            log "FINISHED : $i : flye"
            else
            log "ALREADY FINISHED : $i : flye"
        fi 
    done

    log "FINISHED : flye-assembler step"
###############################################################################
# step-02: run metaquast
	log "STARTED : metaquast step"

    for i in $(cat $sublist); do  
        if [ ! -d $raw_files/$i/quast ] ; then 

            log "STARTED : $i"
            mkdir $raw_files/$i/quast 

            ( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
            -o $raw_files/$i/quast/ \
            $raw_files/$i/assembly.fasta ) > /dev/null 2>&1

            log "FINISHED : $i"
            else
            log "ALREADY FINISHED : $i"
        fi
    done 

    log "FINISHED : metaquast step"
###############################################################################
## step-03: create summary.metaquast.tsv
    log "STARTED : creating summary.metaquast.tsv step"

    if [ ! -f $wd/summary.metaquast.tsv ] ; then 
		for i in $(cat $sublist); do

            if [ -f $raw_files/$i/assembly.fasta ]; then 
                cp $raw_files/$i/assembly.fasta $wd/all_fasta/$i.fasta
            fi

			if [ -f $raw_files/$i/assembly.fasta ] ; then 
                awk 'NR>1 {print $0}' $raw_files/$i/quast/transposed_report.tsv \
				| sed "s/assembly/$i/g" \
				> $raw_files/$i/$i.metaquast.txt 
				else
				echo $i > $raw_files/$i/$i.metaquast.txt 
				for i in {1..22}; do echo "na" >> $raw_files/$i/$i.metaquast.txt ; done
			fi

		done 

        cat /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt > $wd/summary.metaquast.tsv
        for i in $(cat $sublist); do  
            if ! grep -q "text_to_search" $wd/summary.metaquast.tsv; then
                cat $raw_files/$i/$i.metaquast.txt >> $wd/summary.metaquast.tsv
            fi 
        done 
    fi

    log "FINISHED : creating summary.metaquast.tsv step"
###############################################################################
## step-04: count number of contigs and the length of the fasta 
    log "STARTED : step-04: count number of contigs and the length of the fasta"


		for i in $(cat $sublist ) ; do 

            if [ -f $raw_files/$i/assembly.fasta ]; then
                number_of_contigs=$( grep -c ">" $raw_files/$i/assembly.fasta | awk '{print $1}' )
                fasta_length=$( grep -v '^>' $raw_files/$i/assembly.fasta | tr -d '\n' | wc -c )
                echo -e "$i\t$number_of_contigs\t$fasta_length" >> $wd/summary.tsv
                else
                echo -e "$i\t0\t0" >> $wd/summary.tsv
            fi

		done 


    header="id"$'\t'"number_of_contigs"$'\t'"fasta_length"
    if ! grep -q "^$header$" $wd/summary.tsv; then
        sed -i "1i$header" $wd/summary.tsv
    fi

    log "FINISHED : step-04: count number of contigs and the length of the fasta"
###############################################################################
log "FINISHED SBATCH : $pipeline : $sublist"
############################################################################### 