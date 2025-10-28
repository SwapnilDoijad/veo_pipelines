#!/bin/bash
#SBATCH --job-name=0645_phage_host_prediction_by_iphop
#SBATCH --partition=long
#SBATCH --output=results/0645_phage_host_prediction_by_iphop/tmp/slurm/%j.out
#SBATCH --error=results/0645_phage_host_prediction_by_iphop/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0645_phage_host_prediction_by_iphop
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -----------------------------"
###############################################################################
	fasta_path=$(grep "my_fasta_path" $parameters | awk '{print $2}')
	sublist=$wd/tmp/lists/ABC

	log "RUNNING: $pipeline for $sublist"
	
		# source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
		# conda activate iphop_v1.3.3 
		source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
		conda activate iPhop_v1.4.1

		for i in $(cat $sublist); do
			if [ ! -d $raw_files/$i ]; then
				log "RUNNING : $pipeline for $i"

				(mkdir $raw_files/$i) > /dev/null 2>&1
				
				iphop predict \
				--fa_file $fasta_path/$i.fasta \
				--num_threads $SLURM_CPUS_PER_TASK \
				--db_dir /veodata/03/databases/iphop/vJun_2025_pub_rw/Jun_2025_pub_rw/ \
				--out_dir $raw_files/$i/

				log "FINISHED: $pipeline for $sublist"
				else
				log "ALREADY FINISHED: $pipeline for $i"
			fi
		done 

	log "FINISHED: $pipeline for $sublist"
###############################################################################
## footer
	log "ENDED: $pipeline -----------------------------"
###############################################################################