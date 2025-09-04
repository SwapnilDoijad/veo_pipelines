#!/bin/bash
#SBATCH --job-name 0673_identifying_close_relative_in_userSpecified_database_by_blast
#SBATCH --partition=short,long,standard,gpu-veo,gpu,gpu-test
#SBATCH --output results/0673_identifying_close_relative_in_userSpecified_database_by_blast/tmp/slurm/%j.out
#SBATCH --error results/0673_identifying_close_relative_in_userSpecified_database_by_blast/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
###############################################################################
## preparation
    pipeline=0673_identifying_close_relative_in_userSpecified_database_by_blast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    database_fasta=$(grep "my_database_fasta" $parameters | awk '{print $NF}')
    query_fasta_dir=$(grep "my_query_fasta_dir" $parameters | awk '{print $NF}')
	db_name=$(basename $database_fasta)
	query_coverage=$(grep "my_query_coverage" $parameters | awk '{print $NF}')
	identity=$(grep "my_identity" $parameters | awk '{print $NF}')

	sublist=$wd/tmp/lists/ABC
###############################################################################
	log "STARTED : $pipeline for $sublist"
###############################################################################
## run blast
	for i in $(cat $sublist); do
		# if [ ! -f $raw_files/$i.blastn ] ; then 
		# 	log "STARTED : blast for $i"

			# /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
			# -query $query_fasta_dir/$i.fasta \
			# -db $wd/blastdb/$db_name \
			# -out $raw_files/$i.blastn \
			# -outfmt "6 qseqid sseqid qlen slen qstart qend sstart send length mismatch pident evalue bitscore" \
			# -num_threads $SLURM_CPUS_PER_TASK -max_target_seqs 100 -max_hsps 1

			# sed -i -e "1i qseqid\tsseqid\tqlen\tslen\tqstart\tqend\tsstart\tsend\tlength\tmismatch\tpident\tevalue\tbitscore" $raw_files/$i.blastn

			## filter results
			# awk -v id="$identity" -v cov="$query_coverage" 'NR>1 && ($11 >= id) && (($9*100)/$3 >= cov)' $raw_files/$i.blastn > $raw_files/$i.blastn.filtered_"${query_coverage}pcov_${identity}pid"
			# sed -i -e "1i qseqid\tsseqid\tqlen\tslen\tqstart\tqend\tsstart\tsend\tlength\tmismatch\tpident\tevalue\tbitscore" $raw_files/$i.blastn.filtered_$query_coverage"pcov"_"$identity"pid

			## get_fasta

			source /home/groups/VEO/tools/python/biopython/bin/activate

			mkdir -p $wd/fasta/$i
			for i2 in $(awk 'NR>1 {print $2}' $raw_files/$i.blastn.filtered_$query_coverage"pcov"_"$identity"pid); do
				python $suppl_scripts/utilities/fastagrep_python.py \
				-i $database_fasta \
				-o $wd/fasta/$i \
				-H $i2
			done

		# 	log "FINISHED : blast for $i"
		# 	else
		# 	log "ALREADY FINISHED : blast for $i"
		# fi
	done 
###############################################################################
# ## annotate blast results
# 	for i in $(cat $sublist); do

# 		awk '{print $2}' $raw_files/$i.blastn \
# 		> $raw_files/$i.contig.ids

# 		awk '{print $3}' $raw_files/$i.blastn \
# 		> $raw_files/$i.blastn.ids

# 		rm -rf $raw_files/$i.blastn.ids.hits > /dev/null 2>&1
# 		for i2 in $(cat $raw_files/$i.blastn.ids ); do 
# 			i3=$(echo $i2 | awk -F'|' '{print $4}')
# 			hit=$(/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastdbcmd \
# 			-db /veodata/03/databases/ncbi/v20230721/nt/nt \
# 			-entry $i3 | grep ">" | sed 's/>//g')

# 			if [ -z $hit ]; then 
# 				hit="no_hit_found"
# 			fi

# 			echo $hit | tee -a $raw_files/$i.blastn.ids.hits
# 		done 

# 		paste $raw_files/$i.blastn \
# 		$raw_files/$i.blastn.ids.hits \
# 		> $raw_files/$i.blastn.ids.hits.out 

# 		awk '!seen[$2]++' $raw_files/$i.blastn.ids.hits.out \
# 		> $raw_files/$i.blastn.ids.hits.out.best
# 	done 
###############################################################################
log "FINISHED : $pipeline for $sublist" # && clean
###############################################################################