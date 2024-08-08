#!/bin/bash
#SBATCH --job-name 0672_identifying_close_relative_in_nr_by_blast
#SBATCH --partition=interactive
#SBATCH --output results/0672_identifying_close_relative_in_nr_by_blast/tmp/slurm/%j.out
#SBATCH --error results/0672_identifying_close_relative_in_nr_by_blast/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################
## preparation
    pipeline=0672_identifying_close_relative_in_nr_by_blast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    fasta_dir=$(grep "my_fasta_dir" $parameters | awk '{print $NF}')
    create_directories_structure_1 $wd
	sublist=results/$pipeline/tmp/lists/ABC
###############################################################################
## run blast
    echo "STARTED : $pipeline --------------------------------------"
	for i in $(cat $sublist); do
		if [ ! -f $raw_files/$i.blastn ] ; then 
			log "STARTED : blast for $i"
			/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn \
			-query $fasta_dir/$i.fasta \
			-db /work/groups/VEO/databases/ncbi/v20230721/nt/nt \
			-out $raw_files/$i.blastn \
			-outfmt "6 qseqid sseqid qlen slen qstart qend sstart send length mismatch pident evalue bitscore " \
			-num_threads 80 -max_target_seqs 3 -max_hsps 1
			log "FINISHED : blast for $i"
			else
			log "ALREADY FINISHED : blast for $i"
		fi
	done 
###############################################################################
## annotate blast results
	for i in $(cat $sublist); do

		awk '{print $2}' $raw_files/$i.blastn \
		> $raw_files/$i.blastn.ids

		for i2 in $(cat $raw_files/$i.blastn.ids ); do 
			i3=$(echo $i2 | awk -F'|' '{print $4}')
			hit=$(/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastdbcmd \
			-db /work/groups/VEO/databases/ncbi/v20230721/nt/nt \
			-entry $i3 | grep ">" | sed 's/>//g')
			echo $i $i2 $hit | tee -a $raw_files/$i.blastn.ids.hits
		done 

		paste $raw_files/$i.blastn \
		$raw_files/$i.blastn.ids.hits \
		$raw_files/$i.blastn.ids.hits.out 
	done 
###############################################################################