#!/bin/bash
#SBATCH --job-name 0672_identifying_close_relative_in_nr_by_blast
#SBATCH --partition=interactive
#SBATCH --output results/0672_identifying_close_relative_in_nr_by_blast/tmp/slurm/%j.out
#SBATCH --error results/0672_identifying_close_relative_in_nr_by_blast/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
###############################################################################
## preparation
    pipeline=0672_identifying_close_relative_in_nr_by_blast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    fasta_dir=$(grep "my_fasta_dir" $parameters | awk '{print $NF}')
    create_directories_structure_1 $wd
	sublist=$wd/tmp/lists/ABC
###############################################################################
	log "STARTED : $pipeline for $sublist"
###############################################################################
## run blast
	for i in $(cat $sublist); do
		if [ ! -f $raw_files/$i.blastn ] ; then 
			log "STARTED : blast for $i"
			/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
			-query $fasta_dir/$i.fasta \
			-db /veodata/03/databases/ncbi/v20230721/nt/nt \
			-out $raw_files/$i.blastn \
			-outfmt "6 qseqid sseqid qlen slen qstart qend sstart send length mismatch pident evalue bitscore " \
			-num_threads 80 -max_target_seqs 3 -max_hsps 1

			sed -i "s/^/$i\t/" $raw_files/$i.blastn
			log "FINISHED : blast for $i"
			else
			log "ALREADY FINISHED : blast for $i"
		fi
	done 
###############################################################################
## annotate blast results
	for i in $(cat $sublist); do

		awk '{print $2}' $raw_files/$i.blastn \
		> $raw_files/$i.contig.ids

		awk '{print $3}' $raw_files/$i.blastn \
		> $raw_files/$i.blastn.ids

		rm -rf $raw_files/$i.blastn.ids.hits > /dev/null 2>&1
		for i2 in $(cat $raw_files/$i.blastn.ids ); do 
			i3=$(echo $i2 | awk -F'|' '{print $4}')
			hit=$(/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastdbcmd \
			-db /veodata/03/databases/ncbi/v20230721/nt/nt \
			-entry $i3 | grep ">" | sed 's/>//g')

			if [ -z $hit ]; then 
				hit="no_hit_found"
			fi

			echo $hit | tee -a $raw_files/$i.blastn.ids.hits
		done 

		paste $raw_files/$i.blastn \
		$raw_files/$i.blastn.ids.hits \
		> $raw_files/$i.blastn.ids.hits.out 

		awk '!seen[$2]++' $raw_files/$i.blastn.ids.hits.out \
		> $raw_files/$i.blastn.ids.hits.out.best
	done 
###############################################################################
log "FINISHED : $pipeline for $sublist" && clean
###############################################################################