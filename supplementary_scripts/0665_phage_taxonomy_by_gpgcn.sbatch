#!/bin/bash
#SBATCH --job-name=0665_phage_taxonomy_by_gpgcn
#SBATCH --partition=gpu
#SBATCH --output=results/0665_phage_taxonomy_by_gpgcn/tmp/slurm/%j.out
#SBATCH --error=results/0665_phage_taxonomy_by_gpgcn/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
#SBATCH --gres=gpu:1
###############################################################################
## header
	pipeline=0665_phage_taxonomy_by_gpgcn
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	sublist=$wd/tmp/lists/ABC

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
	# conda activate gpgcn_v250810
	conda activate gcnframe_env_v250821
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
##
	for i in $(cat $sublist); do
	 	mkdir $raw_files/$i
		
		python $suppl_scripts/0665_phage_taxonomy_by_gpgcn.preprocess.py \
		--fasta_file $fasta_directory/$i.fasta \
		--phylum_file /veodata/03/databases/ictv/0665_GPGCN/ICTV_TaxoChallenge_id_phylum.txt \
		--model_path /veodata/03/databases/ictv/0665_GPGCN/GCN_model_43587.pt \
		--numeric_labels_path /veodata/03/databases/ictv/0665_GPGCN/phylum_numeric_labels.txt \
		--label_mapping_path /veodata/03/databases/ictv/0665_GPGCN/phylum_label_mapping.txt \
		--embedding_save_path $raw_files/$i/embeddings.npy \
		& my_pid=$!
		get_resource_stat $my_pid $resource_log/$i.preprocess.tsv
	done

###############################################################################
	log "FINISHED: $pipeline -----------------------------" ## && clean
###############################################################################

