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
	# sublist=$wd/tmp/lists/ABC
	sublist=/vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/results/0665_phage_taxonomy_by_gpgcn/tmp/lists/list.0665_phage_taxonomy_by_gpgcn_000

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
	# conda activate gpgcn_v250810
	conda activate gcnframe_env_v250821
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
##
	for i in $(cat $sublist); do
	 	# mkdir $raw_files/$i > /dev/null 2>&1 

					## scripts for model creation

				## generate embeddings
				## This step involves embedding the data using GP-GCN (Gapped Pattern Graph Convolutional Networks).
				## A model is pre-trained using the GCNmodel, and the input data is processed to generate an embedded matrix.
							## depreciated
								# log "STARTED: $i.preprocess (generates embeddings) -----------------------------"
								# python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/GCN_embedding_pipeline_all.py \
								# --fasta_file $fasta_directory/$i.fasta \
								# --phylum_file /veodata/03/databases/ictv/0665_GPGCN/ICTV_TaxoChallenge_id_phylum.txt \
								# --model_path /veodata/03/databases/ictv/0665_GPGCN/GCN_model_43587.pt \
								# --numeric_labels_path /veodata/03/databases/ictv/0665_GPGCN/phylum_numeric_labels.txt \
								# --label_mapping_path /veodata/03/databases/ictv/0665_GPGCN/phylum_label_mapping.txt \
								# --embedding_save_path $raw_files/$i/embeddings.npy \
								# & my_pid=$!
								# get_resource_stat $my_pid $resource_log/$i.preprocess.tsv

					# log "STARTED: $i.preprocess GCN_embedding_pipeline_1 -----------------------------"
					# python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/GCN_embedding_pipeline_1.py \
					# --label_file /veodata/03/databases/ictv/0665_GPGCN/ICTV_TaxoChallenge_id_phylum.txt \
					# --numeric_labels_file $raw_files/$i/phylum_numeric_labels.txt \
					# --label_mapping_file $raw_files/$i/phylum_label_mapping.txt \
					# & my_pid=$!
					# get_resource_stat $my_pid $resource_log/$i.GCN_embedding_pipeline_1.tsv

					# log "STARTED: $i.preprocess GCN_embedding_pipeline_2 -----------------------------"
					# python  $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/GCN_embedding_pipeline_2.py \
					# --fasta_file $fasta_directory/$i.fasta \
					# --label_file $raw_files/$i/phylum_numeric_labels.txt \
					# --model_output_path  $raw_files/$i/GCN_model.pt \
					# & my_pid=$!
					# get_resource_stat $my_pid $resource_log/$i.GCN_embedding_pipeline_2.tsv

					# log "STARTED: $i.preprocess GCN_embedding_pipeline_3 -----------------------------"
					# python  $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/GCN_embedding_pipeline_3.py \
					# 	--dataset $fasta_directory/$i.fasta \
					# 	--label_file $raw_files/$i/phylum_numeric_labels.txt \
					# 	--model_path $raw_files/$i/GCN_model.pt \
					# 	--batch_size 32 \
					# 	--output_embeddings $raw_files/$i/GCN_embeddings.pt \
					# 	--output_labels $raw_files/$i/GCN_labels.pt \
					# 	& my_pid=$!
					# 	get_resource_stat $my_pid $resource_log/$i.GCN_embedding_pipeline_3.tsv


					## generate RSCU (Relative Synonymous Codon Usage)
					log "STARTED: $i.calculate_RSCU (Relative Synonymous Codon Usage)"
					python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/calculate_RSCU.py \
					--fasta_file $fasta_directory/$i.fasta \
					--output_file $raw_files/$i/$i.RSCU.txt \
					& my_pid=$!
					get_resource_stat $my_pid $resource_log/$i.calculate_RSCU.tsv

					## generate TNF (Tetranucleotide Frequency)
					log "STARTED: $i.calculate_TNF (Tetranucleotide Frequency)"
					python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/calculate_TNF.py \
					--fasta_file $fasta_directory/$i.fasta \
					--output_csv $raw_files/$i/$i.TNF.txt \
					& my_pid=$!
					get_resource_stat $my_pid $resource_log/$i.calculate_TNF.tsv
					mv kernel.npz $raw_files/$i/$i.kernel.npz

								## depreciated
									# log "STARTED: $i.train -----------------------------"
									# python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/model/train.py \
									# --datax_path /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/tmp/datax_compat.npy \
									# --datay_path /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/tmp/datay_compat.npy \
									# --batch_size 32 \
									# --num_epochs 30 \
									# --model_save_path $raw_files/$i/$i.model.pt \
									# & my_pid=$!
									# get_resource_stat $my_pid $resource_log/$i.train.tsv

									# python $tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/process.py \
									# --taxonomy_csv $tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/train/virus_taxonomy.csv \
									# --add_names_txt $tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/train/add_names.txt \
									# --combine_rscu_csv $tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/train/combine_RSCU.csv \
									# --virus_final_tnf_csv /veodata/03/databases/ictv/0665_GPGCN/ICTV_TNF.csv \
									# --word2vec_model $raw_files/$i/$i.word2vec.model \
									# --encoders_pkl $raw_files/$i/$i.encoders.pkl \
									# --datax $raw_files/$i/$i.datax.npy \
									# --datay $raw_files/$i/$i.datay.npy \
									# & my_pid=$!
									# get_resource_stat $my_pid $resource_log/$i.process.tsv

									## it was broken for above step ##

		## script for preprocessing of the raw-data
		## This ensures the data is cleaned, normalized, and formatted consistently with the training data.
		# log "STARTED: $i.prediction_process -----------------------------"
		# python /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/prediction_process.py \
		# --rscu_path /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/prediction/ICTV_RSCU.csv \
    	# --tnf_path /veodata/03/databases/ictv/0665_GPGCN/ICTV_TNF.csv \
    	# --taxonomy_path /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/prediction/final_ICTVChallenge_taxonomy_result.csv \
    	# --encoders_path /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/tmp/encoders.pkl \
    	# --output_filtered_path $raw_files/$i.filtered_raw_classdf.csv \
    	# --output_preprocessed_path $raw_files/$i.datax_pre.pkl \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.prediction_process.tsv

		# log "STARTED: $i.prediction -----------------------------"
		# python /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/model/prediction.py \
		# -m /vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/results/0665_phage_taxonomy_by_gpgcn/raw_files/all59907/all59907.model.pt \
		# -i $raw_files/$i.datax_pre.pkl \
		# -o $raw_files/$i.predict.pkl \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.prediction.tsv

		# log "STARTED: $i.result_process -----------------------------"
		# python /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/dataprocess/result_process.py \
		# --encoders /home/groups/VEO/tools/gpgcn/v250810/ICTVTaxoChallenge_model/data/tmp/encoders.pkl \
		# --pred_data /vast/xa73pav/projects/p_swapnil_bechmarking_viralTaxonomy/results/0665_phage_taxonomy_by_gpgcn/raw_files/all59907.predict.pkl \
		# --raw_data  $raw_files/$i.filtered_raw_classdf.csv \
		# --output $raw_files/$i.final_classdf.csv \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/$i.result_process.tsv


	done

###############################################################################
	log "FINISHED: $pipeline -----------------------------" ## && clean
###############################################################################

#  Which script should I run, and what should be my inputs? (to benchmark the time and RAM usage for the script that will predict the taxonomy for 59,907 ICTV sequences.)

# If I am correct....  I should process.ipynb, right? 

# Here, this script is giving me an error. 

# Traceback (most recent call last):
#   File "dataprocess/process.py", line 95, in <module>
#     word2vec_model = Word2Vec(sentences=node_names, vector_size=16, window=3, min_count=1, workers=4)
#   File "/vast/groups/VEO/tools/miniconda3_2024/envs/gcnframe_env_v250821/lib/python3.8/site-packages/gensim/models/word2vec.py", line 430, in __init__
#     self.train(
#   File "/vast/groups/VEO/tools/miniconda3_2024/envs/gcnframe_env_v250821/lib/python3.8/site-packages/gensim/models/word2vec.py", line 1045, in train
#     self._check_training_sanity(epochs=epochs, total_examples=total_examples, total_words=total_words)
#   File "/vast/groups/VEO/tools/miniconda3_2024/envs/gcnframe_env_v250821/lib/python3.8/site-packages/gensim/models/word2vec.py", line 1554, in _check_training_sanity
#     raise RuntimeError("you must first build vocabulary before training the model")
# RuntimeError: You must first build a vocabulary before training the model

# If I look at your script to troubleshoot, 

# tnfdf=pd.read_csv('../data/train/virus_final_tnf.csv', sep=',')
# contigId are
# CASDWV010005094  
# CASDWV010005080

# in my case, I gave input ICTV_TNF.csv that you provided, but here the IDs are different
# ICTVTaxoChallenge_204431
# ICTVTaxoChallenge_886233

# I believe this mismatch is resulting in the error. 
