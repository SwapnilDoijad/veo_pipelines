#!/bin/bash
#SBATCH --job-name 0223_gene_detection_virulence_VFDB_by_blast
#SBATCH --partition=gpu
#SBATCH --output results/0223_gene_detection_virulence_VFDB_by_blast/tmp/slurm/%j.out
#SBATCH --error  results/0223_gene_detection_virulence_VFDB_by_blast/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0223_gene_detection_virulence_VFDB_by_blast
    wd=results/$pipeline
    cpus=$SLURM_CPUS_PER_TASK

    sublist=$wd/tmp/lists/ABC
    parameter_file=tmp/parameters/$pipeline.*

    annotation_file=/work/groups/VEO/databases/VFDB/v2021/VFDB-annotations.txt

	blastn=/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn
    fasta_path=$(grep my_fasta_path $parameter_file | awk '{print $2}')
###############################################################################
## step-02: 
	for i in $(cat $sublist); do

		if [ ! -f $wd/raw_files/$i/$i.virulence-gene-blast.tmp ]; then
			mkdir $wd/raw_files/$i/ > /dev/null 2>&1

			log "STARTED : $pipeline : $i : blastn step"
			$blastn \
            -db /work/groups/VEO/databases/VFDB/v2021/VFDB_setB_nt.fas \
			-query $fasta_path/$i.fasta \
			-out $wd/raw_files/$i/$i.virulence-gene-blast.tmp \
			-num_threads $cpus -max_target_seqs 1 -max_hsps 1 -evalue 1e-100 \
            -outfmt "6 sseqid qseqid sstart send qstart qend slen qlen evalue bitscore length mismatch gaps pident qcovs"
            log "Finished : $pipeline : $i : blastn step"
			else
			log "ALREADY FINISHED : $pipeline : $i : blastn step"
		fi 

		mkdir $wd/all_results > /dev/null 2>&1

		# filtering the output for total-query-covergae >99% and total-protein identity >70%
		awk -F'\t' '{print ($8/$7*100) }' $wd/raw_files/$i/$i.virulence-gene-blast.tmp \
        > $wd/raw_files/$i/$i.total-query-covered.tmp

		paste $wd/raw_files/$i/$i.virulence-gene-blast.tmp $wd/raw_files/$i/$i.total-query-covered.tmp \
        > $wd/raw_files/$i/$i.virulence-gene-blast.total-query-covered.tmp

		awk -F'\t' '$14 > 70' $wd/raw_files/$i/$i.virulence-gene-blast.total-query-covered.tmp \
        | awk -F'\t' '$16 > 95' > $wd/raw_files/$i/$i.virulence-gene-blast.total-query-covered.filtered.tmp
		#--------------------

		awk -f /home/groups/VEO/scripts_for_users/supplementary_scripts/vlookup-VFDB.awk \
        $annotation_file \
        $wd/raw_files/$i/$i.virulence-gene-blast.total-query-covered.filtered.tmp > $wd/raw_files/$i/$i.tmp1.tmp

		sed -i 's/_/ /g' $wd/raw_files/$i/$i.tmp1.tmp

		paste $wd/raw_files/$i/$i.virulence-gene-blast.total-query-covered.filtered.tmp \
        $wd/raw_files/$i/$i.tmp1.tmp > $wd/all_results/$i.VFDB-blast.csv

		ex -sc '1i|sseqid	qseqid	sstart	send	qstart	qend	slen	qlen	evalue	bitscore	length	mismatch	gaps	pident	qcovs	total-query-coverage	gene	protein	group	originated-from' -cx $wd/all_results/$i.VFDB-blast.csv

		log "Finished : $pipeline : $i : filtering step"


    done
###############################################################################