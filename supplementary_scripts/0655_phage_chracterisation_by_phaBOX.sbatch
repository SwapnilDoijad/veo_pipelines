#!/bin/bash
#SBATCH --job-name=0655_phage_chracterisation_by_phaBOX
#SBATCH --partition=standard,long
#SBATCH --output=results/0655_phage_chracterisation_by_phaBOX/tmp/slurm/%j.out
#SBATCH --error=results/0655_phage_chracterisation_by_phaBOX/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0655_phage_chracterisation_by_phaBOX
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	task=$(grep my_task $parameters | awk '{print $2}')
	sublist=$wd/tmp/lists/ABC
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## run phaBox
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate phabox2_v2.1.12

	for i in $(cat $sublist); do
		log "STARTED: $i"

		mkdir -p $raw_files/$i

		phabox2 \
		--task $task \
		--dbdir /veodata/03/databases/phabox/v2_250807/phabox_db_v2_1 \
        --outpth $raw_files/$i \
		--len 1000 \
        --contigs $fasta_directory/$i.fasta \
        --threads $SLURM_CPUS_PER_TASK \
		& my_pid=$! 
		get_resource_stat $my_pid $resource_log/$i.phabox2.$task.tsv

	done

	conda deactivate
###############################################################################
	log "FINISHED: $pipeline -----------------------------" && clean 
###############################################################################

