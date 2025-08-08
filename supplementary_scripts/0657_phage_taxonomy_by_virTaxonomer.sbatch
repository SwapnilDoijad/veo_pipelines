#!/bin/bash
#SBATCH --job-name=0657_phage_taxonomy_by_virTaxonomer
#SBATCH --partition=standard,long
#SBATCH --output=results/0657_phage_taxonomy_by_virTaxonomer/tmp/slurm/%j.out
#SBATCH --error=results/0657_phage_taxonomy_by_virTaxonomer/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0657_phage_taxonomy_by_virTaxonomer
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	taxa_level=$( grep my_taxa_level $parameters | awk '{print $2}' )
	sublist=$wd/tmp/lists/ABC
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## run sourmash
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
	conda activate VirTaxonomer_v250808
	export PYTHONPATH=$PYTHONPATH:/home/groups/VEO/tools/virTaxonomer/v250808/VirTaxonomer/code

	for i in $(cat $sublist); do
		log "STARTED: $i"

		mkdir -p $raw_files/$i

		log "Running VirTaxonomer for $i : highest"
		python /home/groups/VEO/tools/virTaxonomer/v250808/VirTaxonomer/code/main.py \
		--input $fasta_dir/$i.fasta \
		--model /veodata/03/databases/virTaxonomer/v250808 \
		--output $raw_files/$i \
		--ML highest \
		--restrict $taxa_level \
		--batchsize 128 \
		& my_pid=$! 
		get_resource_stat $my_pid $wd/tmp/resource_log/$i.virTaxonomer.highest.tsv

		log "Running VirTaxonomer for $i : bottomup"
		python /home/groups/VEO/tools/virTaxonomer/v250808/VirTaxonomer/code/main.py \
		--input $fasta_dir/$i.fasta \
		--model /veodata/03/databases/virTaxonomer/v250808 \
		--output $raw_files/$i \
		--ML bottomup \
		--restrict $taxa_level \
		--batchsize 128 \
		& my_pid=$! 
		get_resource_stat $my_pid $wd/tmp/resource_log/$i.virTaxonomer.bottomup.tsv

	done
	conda deactivate
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean 
###############################################################################

