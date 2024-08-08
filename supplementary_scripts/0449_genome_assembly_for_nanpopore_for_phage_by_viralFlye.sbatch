#!/bin/bash
#SBATCH --job-name 0449_genome_assembly_for_nanpopore_for_phage_by_viralFlye
#SBATCH --partition=interactive
#SBATCH --output results/0449_genome_assembly_for_nanpopore_for_phage_by_viralFlye/tmp/slurm/%j.out
#SBATCH --error results/0449_genome_assembly_for_nanpopore_for_phage_by_viralFlye/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################
## step-00: preparation
    pipeline=0449_genome_assembly_for_nanpopore_for_phage_by_viralFlye
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    conda activate viralFlye_v0.2
    sublist=$wd/tmp/lists/ABC
############################################################################### 
log "STARTED SBATCH : $pipeline : $sublist"
############################################################################### 
## step-01: run virtalFlye-assembler
    log "STARTED : viralFlye-assembler step"

    for i in $(cat $sublist); do
        if [ ! -d $raw_files/$i ]; then 
            log "STARTED : $i : viralFlye"

            /home/groups/VEO/tools/viralFlye/v0.2/viralFlye.py \
            --threads $SLURM_CPUS_PER_TASK \
            --dir /home/xa73pav/projects/p_natia_phage/results/0048_genome_assembly_by_flye/raw_files/$i \
            --hmm /work/groups/VEO/databases/pfam/v34.0/Pfam-A.hmm.gz \
            --reads data/my_fastq_filtered_Q10_2000_75000_based_on_kmers_5K/$i.fastq.gz \
            --outdir $raw_files/$i 
            log "FINISHED : $i : viralFlye"
            else
            log "ALREADY FINISHED : $i : viralFlye"
        fi 
    done

    log "FINISHED : viralFlye-assembler step"


###############################################################################
# step-02: run metaquast
	# log "STARTED : metaquast step"

    # for i in $(cat $sublist); do  
    #     if [ ! -d $raw_files/$i/quast ] ; then 

    #         log "STARTED : $i"
    #         mkdir $raw_files/$i/quast 

    #         ( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
    #         -o $raw_files/$i/quast/ \
    #         $raw_files/$i/assembly.fasta ) > /dev/null 2>&1

    #         log "FINISHED : $i"
    #         else
    #         log "ALREADY FINISHED : $i"
    #     fi
    # done 

    # log "FINISHED : metaquast step"
###############################################################################
## step-03: create summary.metaquast.tsv
    # log "STARTED : creating summary.metaquast.tsv step"

    # if [ ! -f $wd/summary.metaquast.tsv ] ; then 
	# 	for i in $(cat $sublist); do

    #         if [ -f $raw_files/$i/assembly.fasta ]; then 
    #             cp $raw_files/$i/assembly.fasta $wd/all_fasta/$i.fasta
    #         fi

	# 		if [ -f $raw_files/$i/assembly.fasta ] ; then 
    #             awk 'NR>1 {print $0}' $raw_files/$i/quast/transposed_report.tsv \
	# 			| sed "s/assembly/$i/g" \
	# 			> $raw_files/$i/$i.metaquast.txt 
	# 			else
	# 			echo $i > $raw_files/$i/$i.metaquast.txt 
	# 			for i in {1..22}; do echo "na" >> $raw_files/$i/$i.metaquast.txt ; done
	# 		fi

	# 	done 

    #     cat /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt > $wd/summary.metaquast.tsv
    #     for i in $(cat $sublist); do  
    #         if ! grep -q "text_to_search" $wd/summary.metaquast.tsv; then
    #             cat $raw_files/$i/$i.metaquast.txt >> $wd/summary.metaquast.tsv
    #         fi 
    #     done 
    # fi

    # log "FINISHED : creating summary.metaquast.tsv step"
###############################################################################
## step-04: count number of contigs and the length of the fasta 
    # log "STARTED : step-04: count number of contigs and the length of the fasta"


	# 	for i in $(cat $sublist ) ; do 

    #         if [ -f $raw_files/$i/assembly.fasta ]; then
    #             number_of_contigs=$( grep -c ">" $raw_files/$i/assembly.fasta | awk '{print $1}' )
    #             fasta_length=$( grep -v '^>' $raw_files/$i/assembly.fasta | tr -d '\n' | wc -c )
    #             echo -e "$i\t$number_of_contigs\t$fasta_length" >> $wd/summary.tsv
    #             else
    #             echo -e "$i\t0\t0" >> $wd/summary.tsv
    #         fi

	# 	done 


    # header="id"$'\t'"number_of_contigs"$'\t'"fasta_length"
    # if ! grep -q "^$header$" $wd/summary.tsv; then
    #     sed -i "1i$header" $wd/summary.tsv
    # fi

    # log "FINISHED : step-04: count number of contigs and the length of the fasta"
###############################################################################
log "FINISHED SBATCH : $pipeline : $sublist"
############################################################################### 