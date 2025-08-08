#!/bin/bash
#SBATCH --job-name=0658_phage_taxonomy_by_viratax
#SBATCH --partition=standard,long
#SBATCH --output=results/0658_phage_taxonomy_by_viratax/tmp/slurm/%j.out
#SBATCH --error=results/0658_phage_taxonomy_by_viratax/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0658_phage_taxonomy_by_viratax
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	viratax="/home/groups/VEO/tools/virataxa/v20250808/viratax"
	database="/veodata/03/databases/virataxa/v20250808"
	sublist=$wd/tmp/lists/ABC
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## run sourmash
	module load compiler/gcc/12.2.0
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate virataxa_v250808

	for i in $(cat $sublist); do
		log "STARTED: $i"
		mkdir -p $raw_files/$i

		log "getting labels for $i"
		grep "^>" $fasta_dir/$i.fasta \
			| sed "-es/^>//" \
			> $raw_files/$i/labels.txt \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.labels.tsv

		log "getting orfs for $i"
		getorf \
			-sequence $fasta_dir/$i.fasta \
			-outseq $raw_files/$i/orfs.fasta \
			-minsize 99 \
			-find 0 \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.getorfs.tsv

		log "relabeling orfs for $i"
		$viratax/scripts/relabel_orfs.py \
			$raw_files/$i/orfs.fasta \
			> $raw_files/$i/orfs_relabel.fasta \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.relabel_orfs.tsv

		log "running minimap2 sketch for $i"
		minimap2 \
			-t $SLURM_CPUS_PER_TASK \
			$database/gb.fa \
			$fasta_dir/$i.fasta \
			> $raw_files/$i/minimap2.paf \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.minimap2.tsv

		log "getting top hits for $i"
			$viratax/scripts/top_nt_hit.py \
			--hits-file $raw_files/$i/minimap2.paf \
			> $raw_files/$i/top_nt_hit.tsv \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.top_nt_hits.tsv

		log "getting top hits for orfs for $i"
		$viratax/scripts/not_species_orfs.py \
			--orfs-file $raw_files/$i/orfs_relabel.fasta \
			--hits-file $raw_files/$i/top_nt_hit.tsv \
			> $raw_files/$i/not_species_orfs.fasta \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.not_species_orfs.tsv

		log "running diamond blastp for $i"
		diamond blastp \
			--quiet \
			--query $raw_files/$i/not_species_orfs.fasta \
			--db $database/gb \
			--threads $SLURM_CPUS_PER_TASK \
			--sensitive \
			--out $raw_files/$i/diamond_hits.tsv \
			--outfmt 6 qseqid qlen sseqid slen qstart qend sstart send evalue pident \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.blastp.tsv
		
		# diamond files need to get written
		sleep 20

		log "getting top hits for orfs for $i"
		$viratax/scripts/top_orf_hits.py \
		 	--acc2node $database/acc2node.tsv \
			--diamond_hits $raw_files/$i/diamond_hits.tsv \
			> $raw_files/$i/top_orf_hits.tsv \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.top_orf_hits.tsv

		log "getting top hits for species for $i"
		$viratax/scripts/top_orf_hits_species.py \
			--acc2node $database/acc2node.tsv \
			--top_orf_hits $raw_files/$i/top_orf_hits.tsv \
			> $raw_files/$i/top_orf_hits_species.tsv \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.top_orf_hits_species.tsv

		log "getting top hits for species for orfs for $i"
		$viratax/scripts/classify_other.py \
			--acc2node $database/acc2node.tsv \
			--top_orf_hits $raw_files/$i/top_orf_hits_species.tsv \
			--gb_self_hits $database/gb_self_hits_lcts.tsv \
			> $raw_files/$i/classify_other.tsv \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.classify_other.tsv

		log "getting top hits for species for orfs for $i"
		$viratax/scripts/results.py \
			--q_labels $raw_files/$i/labels.txt \
			--acc2node $database/acc2node.tsv \
			--top_nt_hit $raw_files/$i/top_nt_hit.tsv \
			--top_orf_hits_species $raw_files/$i/top_orf_hits_species.tsv \
			--classify_other $raw_files/$i/classify_other.tsv \
			> $raw_files/$i/results.csv \
			& my_pid=$! 
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.results.tsv

	done

###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean 
###############################################################################

