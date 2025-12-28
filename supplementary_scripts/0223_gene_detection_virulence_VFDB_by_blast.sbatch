#!/bin/bash
#SBATCH --job-name=0223_gene_detection_virulence_VFDB_by_blast
#SBATCH --partition=gpu-veo,gpu,gpu-test,standard,long
#SBATCH --output=results/0223_gene_detection_virulence_VFDB_by_blast/tmp/slurm/%j.out
#SBATCH --error=results/0223_gene_detection_virulence_VFDB_by_blast/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
## step-01: preparation
    pipeline=0223_gene_detection_virulence_VFDB_by_blast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    annotation_file=/veodata/03/databases/VFDB/v2021/VFDB-annotations.txt
	blastn=/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn
    fasta_path=$(grep my_fasta_path $parameters | awk '{print $2}')
    cpus=$SLURM_CPUS_PER_TASK
    sublist=$wd/tmp/lists/ABC
	source /home/groups/VEO/tools/biopython/myenv/bin/activate
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-02: 
	for i in $(cat $sublist); do
		if [ ! -f $wd/raw_files/$i/$i.virulence-gene-blast.tmp ]; then
			mkdir $wd/raw_files/$i/ > /dev/null 2>&1

			log "STARTED : $pipeline : $i : blastn step"
			$blastn \
            -db /veodata/03/databases/VFDB/v2021/VFDB_setB_nt.fas \
			-query $fasta_path/$i.fasta \
			-out $wd/raw_files/$i/$i.virulence-gene-blast.tmp \
			-num_threads $cpus -max_target_seqs 1000 -max_hsps 1 -evalue 1e-100 \
            -outfmt "6 sseqid qseqid sstart send qstart qend slen qlen evalue bitscore length mismatch gaps pident qcovs"

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
			$wd/raw_files/$i/$i.virulence-gene-blast.total-query-covered.filtered.tmp \
			| tr ' ' '_' \
			> $wd/raw_files/$i/$i.tmp1.tmp

			paste $wd/raw_files/$i/$i.virulence-gene-blast.total-query-covered.filtered.tmp \
			$wd/raw_files/$i/$i.tmp1.tmp > $wd/all_results/$i.VFDB-blast.csv

			

			## filtering 
				# Default: best per (qseqid, gene, locus), gap 500 bp
					# python best_hits.py -i blast.tsv -o best.tsv
				# Stricter filters
					python $suppl_scripts/$pipeline.filter.py \
					-i $wd/all_results/$i.VFDB-blast.csv \
					-o $wd/all_results/$i.VFDB-blast.tsv \
					--mode query-locus \
					--min-pident 70 --min-scovs 85
				# Simpler collapsing (keep 1 per gene per contig)
					# python best_hits.py -i blast.tsv -o best.tsv --mode query-gene


		
			

			log "Finished : $pipeline : $i : filtering step"
		fi
    done
	
###############################################################################
	log "STARTED: $pipeline -----------------------------" && clean
###############################################################################
#awk 'NR>1' $wd/all_results/$i.VFDB-blast.tsv >> $wd/VFDB-blast.tsv

# source /home/groups/VEO/tools/biopython/myenv/bin/activate

## this will classify genes for e.g. capsule, fimbriae, LPS, toxins, etc.
	# python /home/groups/VEO/scripts_for_users/supplementary_scripts/0223_gene_detection_virulence_VFDB_by_blast.gene_collapse.py \
	# -i /vast/xa73pav/projects/p_swapnil_Enterobacter/results/0223_gene_detection_virulence_VFDB_by_blast/VFDB-blast.matrix.protein.tsv \
	# -o /vast/xa73pav/projects/p_swapnil_Enterobacter/results/0223_gene_detection_virulence_VFDB_by_blast/VFDB-blast.matrix.protein.collapsed.tsv \
	# --report /vast/xa73pav/projects/p_swapnil_Enterobacter/results/0223_gene_detection_virulence_VFDB_by_blast/VFDB-blast.matrix.protein.report.tsv

# python /home/groups/VEO/scripts_for_users/supplementary_scripts/0223_gene_detection_virulence_VFDB_by_blast.add_species.py \
# -i /vast/xa73pav/projects/p_swapnil_Enterobacter/results/0223_gene_detection_virulence_VFDB_by_blast/VFDB-blast.matrix.protein.collapsed.tsv \
# -s /vast/xa73pav/projects/p_swapnil_Enterobacter/id_species.tsv \
# -o /vast/xa73pav/projects/p_swapnil_Enterobacter/results/0223_gene_detection_virulence_VFDB_by_blast/VFDB-blast.matrix.protein.collapsed.with_species.tsv

# python /home/groups/VEO/scripts_for_users/supplementary_scripts/0223_gene_detection_virulence_VFDB_by_blast.species_association.py \
# -i /vast/xa73pav/projects/p_swapnil_Enterobacter/results/0223_gene_detection_virulence_VFDB_by_blast/VFDB-blast.matrix.protein.collapsed.with_species.tsv \
# -o /vast/xa73pav/projects/p_swapnil_Enterobacter/results/0223_gene_detection_virulence_VFDB_by_blast/sp_comparison/out \
# --mode pairwise --global_permutations 500 --seed 7 --min_occurence_of_gene 5 --drop Unknown --min_occurence_of_gene 5 --drop_species unclassified

