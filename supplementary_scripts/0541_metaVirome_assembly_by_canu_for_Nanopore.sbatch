#!/bin/bash
#SBATCH --job-name=0541_metaVirome_assembly_by_canu_for_Nanopore
#SBATCH --partition=standard,long,interactive
#SBATCH --output=results/0541_metaVirome_assembly_by_canu_for_Nanopore/tmp/slurm/%j.out
#SBATCH --error=results/0541_metaVirome_assembly_by_canu_for_Nanopore/tmp/slurm/%j.err
#SBATCH --mem=230G
#SBATCH --cpus-per-task=20
###############################################################################
## header
    pipeline=0541_metaVirome_assembly_by_canu_for_Nanopore
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    cpus=$SLURM_CPUS_PER_TASK
    sublist=$wd/tmp/lists/ABC

    log "SBATCH STARTED : $pipeline : $sublist -----------------------------------"
    log "fastq_path = $fastq_path"
###############################################################################
	## step-01: canu assembly
	## paramteres were set as per developers recommendeation for metagenome assembly
	## https://github.com/marbl/canu/issues/634
	## and https://canu.readthedocs.io/en/latest/faq.html

				# genomeSize=5m \  # Adjust based on expected virome size
				# minInputCoverage=1 \  # Avoid discarding rare viral reads
				# maxInputCoverage=500 \  # Prevent over-represented viruses from skewing assembly
				# corMinCoverage=0 \  # Keep low-abundance viral reads
				# corOutCoverage=200 \  # Limit read correction coverage
				# corMhapSensitivity=high \  # Improve correction of noisy reads
				# correctedErrorRate=0.105 \  # Keep Nanopore-friendly error rate
				# stopOnLowCoverage=1 \  # Allow lower-depth viral contigs
				# cnsMaxCoverage=100 \  # Avoid excessive depth in consensus step
				# oeaMemory=50 \  # Adjust memory for better efficiency
				# redMemory=50 \
				# batMemory=100 

    for i in $(cat $sublist); do
        if [ ! -f $raw_files/$i/$i.contigs.fasta ] ; then 
            log "STARTED: long-read assembly by canu for $i : running"

			mkdir -p $raw_files/$i

            /home/groups/VEO/tools/canu/v2.2/canu-2.2/bin/canu \
            -p $i -d $raw_files/$i \
			genomeSize=5m \
			minInputCoverage=1 \
			maxInputCoverage=500 \
			corMinCoverage=0 \
			corOutCoverage=200 \
			corMhapSensitivity=high \
			correctedErrorRate=0.105 \
			stopOnLowCoverage=1 \
			cnsMaxCoverage=100 \
			oeaMemory=100 \
			redMemory=100 \
			batMemory=200 \
            -nanopore $fastq_path/$i.fastq.gz
			
			log "FINISHED: long-read assembly by canu for $i"
            else
            log "ALREADY FINISHED: long-read assembly by canu for $i : already finished"
        fi
	done
###############################################################################
## step-02: run metaquast
	echo "running metaquast "
	mkdir -p $raw_files/$i/quast/fasta
    for i in $(cat $list); do  
		if [ -f $raw_files/$i/$i.contigs.fasta ] ; then 
			if [ ! -d $raw_files/$i/quast/fasta ] ; then 
				echo "metaquast for $i: running"

				cp $raw_files/$i/$i.contigs.fasta \
				$raw_files/$i/quast/fasta/

				cp $raw_files/$i/assembly.fasta \
				$wd/all_fasta/$i.fasta

				python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
				-o $raw_files/$i/quast/ \
				$raw_files/$i/quast/fasta/* 

				else
				echo "metaquast for $i: already finished"
			fi
		fi
    done 

	for i in $(cat $list); do  
		if [ -f $raw_files/$i/$i.contigs.fasta ] ; then 
			awk -F'\t' '{print $2}' $raw_files/$i/quast/report.tsv \
			> $tmp/$i.metaquast.txt 
			else
			echo $i.contigs > $tmp/$i.metaquast.txt 
			for i in {1..22}; do echo "na" >> $tmp/$i.metaquast.txt ; done
		fi 
	done 
	paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt $tmp/*.metaquast.txt \
	> $summary.tsv
###############################################################################
