#!/bin/bash
#SBATCH --job-name=0662_phage_taxonomy_by_vanjari
#SBATCH --partition=gpu,gpu-test,gpu-veo
#SBATCH --output=results/0662_phage_taxonomy_by_vanjari/tmp/slurm/%j.out
#SBATCH --error=results/0662_phage_taxonomy_by_vanjari/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
#SBATCH --gres=gpu:1
###############################################################################
## header
	pipeline=0662_phage_taxonomy_by_vanjari
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate vanjari_v250814_barbet

###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: file and directory preparation

	## normal mode 
		vanjari \
		--input $fasta_directory/ \
		--output-csv $raw_files/vanjari-0.1.csv \
		& my_pid=$!
		get_resource_stat $my_pid $resource_log/vanjari.tsv

		# vanjari-tools \
		# increase-threshold \
		# --input $raw_files/vanjari-0.1.csv \
		# --output $raw_files/vanjari-0.1-threshold0.5.csv \
		# --threshold 0.5

	# ## fast mode 
	# 	vanjari-fast \
	# 	--input $fasta_directory/ \
	# 	--output-csv $raw_files/vanjari-fast-0.1.csv \
	# 	& my_pid=$!
	# 	get_resource_stat $my_pid $resource_log/vanjari.fast.tsv
		
	# 	## Generate results for ensemble
	# 	vanjari-tools \
	# 	ensemble-csvs \
	# 	--input $raw_files/vanjari-fast-0.1.csv \
	# 	--output $raw_files/vanjari-ensemble-0.1.csv \
	# 	& my_pid=$!
	# 	get_resource_stat $my_pid $resource_log/vanjari.fast.tsv

	# 	vanjari-tools \
	# 	increase-threshold \
	# 	--input $raw_files/vanjari-fast-0.1.csv \
	# 	--output $raw_files/vanjari-fast-0.1-threshold0.5.csv \
	# 	--threshold 0.5

	# 	vanjari-tools \
	# 	increase-threshold \
	# 	--input $raw_files/vanjari-ensemble-0.1.csv \
	# 	--output $raw_files/vanjari-ensemble-0.1-threshold0.5.csv \
	# 	--threshold 0.5


###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean
###############################################################################


# Hi again, 

# While I could run in one hour

# vanjari-fast --input $fasta_directory --output-csv vanjari-fast-0.1.csv

# it took than 3 day to complete ~37K

# vanjari --input $fasta_directory --output-csv $raw_files/vanjari-0.1.csv --memmap-array-path $raw_files/embeddings.npy 
# 		--memmap-index $raw_files/embeddings.txt

# 2025-08-21 09:11:25: STARTED: 0662_phage_taxonomy_by_vanjari -----------------------------
# /vast/groups/VEO/tools/miniconda3_2024/envs/vanjari_v250814_barbet/lib/python3.10/site-packages/lightning/pytorch/utilities/parsing.py:209: Attribute 'model' is an instance of `nn.Module` and is already saved during checkpointing. It is recommended to ignore them using `self.save_hyperparameters(ignore=['model'])`.
# /vast/groups/VEO/tools/miniconda3_2024/envs/vanjari_v250814_barbet/lib/python3.10/site-packages/lightning/pytorch/utilities/parsing.py:209: Attribute 'loss_function' is an instance of `nn.Module` and is already saved during checkpointing. It is recommended to ignore them using `self.save_hyperparameters(ignore=['loss_function'])`.
# 💡 Tip: For seamless cloud uploads and versioning, try installing [litmodels](https://pypi.org/project/litmodels/) to enable LitModelCheckpoint, which syncs automatically with the Lightning model registry.
# GPU available: True (cuda), used: True
# TPU available: False, using: 0 TPU cores
# HPU available: False, using: 0 HPUs
# slurmstepd: error: *** JOB 4261381 ON gpu005 CANCELLED AT 2025-08-24T09:11:52 DUE TO TIME LIMIT ***

	