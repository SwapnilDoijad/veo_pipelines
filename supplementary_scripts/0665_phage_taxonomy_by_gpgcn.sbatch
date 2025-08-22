#!/bin/bash
#SBATCH --job-name=0665_phage_taxonomy_by_gpgcn
#SBATCH --partition=gpu
#SBATCH --output=results/0665_phage_taxonomy_by_gpgcn/tmp/slurm/%j.out
#SBATCH --error=results/0665_phage_taxonomy_by_gpgcn/tmp/slurm/%j.err
#SBATCH --mem=300G
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
	 	# mkdir $raw_files/$i

		# log "STARTED: $i.preprocess -----------------------------"
		# python $suppl_scripts/0665_phage_taxonomy_by_gpgcn.preprocess.py \
		# --fasta_file $fasta_directory/$i.fasta \
		# --phylum_file /veodata/03/databases/ictv/0665_GPGCN/ICTV_TaxoChallenge_id_phylum.txt \
		# --model_path /veodata/03/databases/ictv/0665_GPGCN/GCN_model_43587.pt \
		# --numeric_labels_path /veodata/03/databases/ictv/0665_GPGCN/phylum_numeric_labels.txt \
		# --label_mapping_path /veodata/03/databases/ictv/0665_GPGCN/phylum_label_mapping.txt \
		# --embedding_save_path $raw_files/$i/embeddings.npy \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.preprocess.tsv

		# log "STARTED: $i.calculate_RSCU -----------------------------"
		# python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/calculate_RSCU.py \
		# --fasta_file $fasta_directory/$i.fasta \
		# --output_file $raw_files/$i/$i.RSCU.txt \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.calculate_RSCU.tsv

		# log "STARTED: $i.calculate_TNF -----------------------------"
		# python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/calculate_TNF.py \
		# --fasta_file $fasta_directory/$i.fasta \
		# --output_csv $raw_files/$i/$i.TNF.txt \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.calculate_TNF.tsv
		# mv kernel.npz $raw_files/$i/$i.kernel.npz

		# log "STARTED: $i.train -----------------------------"
		# python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/model/train.py \
		# --datax_path /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/tmp/datax_compat.npy \
		# --datay_path /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/tmp/datay_compat.npy \
		# --batch_size 32 \
		# --num_epochs 30 \
		# --model_save_path $raw_files/$i/$i.model.pt \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.train.tsv

		python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/process.py \
		--taxonomy_csv $tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/train/virus_taxonomy.csv \
		--add_names_txt $tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/train/add_names.txt \
		--combine_rscu_csv $tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/train/combine_RSCU.csv \
		--virus_tnf_csv /veodata/03/databases/ictv/0665_GPGCN/ICTV_TNF.csv \
		--output_dir $raw_files/$i/ \
		& my_pid=$!
		get_resource_stat $my_pid $resource_log/$i.process.tsv


	done

###############################################################################
	log "FINISHED: $pipeline -----------------------------" ## && clean
###############################################################################

