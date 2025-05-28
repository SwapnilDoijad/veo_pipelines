#!/bin/bash
#SBATCH --job-name=0413_find_reference_genome_by_referenceseeker
#SBATCH --partition=short
#SBATCH --output=results/0413_find_reference_genome_by_referenceseeker/tmp/slurm/%j.out
#SBATCH --error=results/0413_find_reference_genome_by_referenceseeker/tmp/slurm/%j.err
#SBATCH --mem=20G
#SBATCH --cpus-per-task=10
###############################################################################
## 00: preparations
    pipeline=0413_find_reference_genome_by_referenceseeker
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	sublist=$wd/tmp/lists/ABC

	database=/veodata/03/databases/referenceseeker/refseq/bacteria-refseq
	# database=/veodata/03/databases/referenceseeker/refseq/plasmids-refseq
	# database=/veodata/03/databases/referenceseeker/refseq/plasmids-plsdb
	fasta_path=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	ref_fasta_needed=$(grep my_ref_fasta_needed $parameters | awk '{print $2}')
	sublist_id=$(echo $sublist | awk -F'/' '{print $NF}' | cut -d'_' -f7 | awk -F'.' '{print $1}')
	export PATH=/home/groups/VEO/tools/edirect:$PATH
###############################################################################
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh \
	&& conda activate referenceseeker_v1.8.0

	while IFS= read -r i; do
		if [ ! -f $raw_files/$i.tsv ]; then
			log "RUNNING: $i"

			## 2025-05-11 09:42:44 @Swapnil, think adding -u (unfiltered) output flag, else, sometimes there is no output
			
			referenceseeker \
			-t $SLURM_CPUS_PER_TASK \
			$database \
			$fasta_path/$i.fasta \
			> $raw_files/$i.tsv \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.referenceseeker.tsv 

			awk 'NR==2' $raw_files/$i.tsv | awk '{print $1}' | sed -e "s/^/${i}\t/"  | tee -a $wd/tmp/$sublist_id.ref_genome.txt

			log "FINISHED: $i"
		else
			log "ALREADY DONE: $i"
		fi
	done < $sublist
###############################################################################
	if [ $ref_fasta_needed == "Yes" ]; then
		mkdir -p $wd/references > /dev/null 2>&1

		while IFS=$'\t' read -r id ref; do
			gunzip -c $database/$ref.fna.gz \
			> $wd/references/${id}_${ref}.fasta
		done < $wd/tmp/$sublist_id.ref_genome.txt

	fi
###############################################################################
