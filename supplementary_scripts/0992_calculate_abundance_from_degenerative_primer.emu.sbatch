#!/bin/bash
###############################################################################
#SBATCH --job-name=0992_emu
#SBATCH --partition=interactive,long,standard,gpu-veo
#SBATCH --output=results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out.emu
#SBATCH --error=results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err.emu
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
pipeline=0992_calculate_abundance_from_degenerative_primer
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

subsample=my_subsample
sample=my_sample
mismatch=my_mismatch
QC=my_qc_value
database=$(grep my_database $parameters  | awk '{print $2}')
tool=$(grep my_tool $parameters | awk '{print $2}')

if [ "$database" = "silva" ]; then
		database_path=/veodata/03/databases/emu/v240807_silva
	elif [ "$database" = "emu" ]; then
		database_path=/veodata/02/databases/emu/v240807
	else
		log "invalid database name: $database"
fi
###############################################################################
## run emu tool

	log "running emu abundance for $subsample $sample $mismatch with database $database"

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate emu_v3.4.5 
	
	emu abundance \
	--type map-ont \
	--db $database_path \
	--output-dir $raw_files/$tool/$database/hits \
	--output-basename $sample.$subsample.$mismatch.$QC \
	--keep-counts \
	--keep-read-assignments \
	--threads $SLURM_CPUS_PER_TASK \
	$raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta \
	& my_pid=$!
	get_resource_stat $my_pid $wd/tmp/resource_log/$sample.$subsample.$mismatch.$QC.$tool.$database.tsv

	sed -i 's/ /_/g' $raw_files/$tool/$database/hits/$sample.$subsample.$mismatch.${QC}_rel-abundance.tsv
	sed -i 's/\t\t/\tunassigned\t/g' $raw_files/$tool/$database/hits/$sample.$subsample.$mismatch.${QC}_rel-abundance.tsv

	mv $raw_files/$tool/$database/hits/$sample.$subsample.$mismatch.${QC}_read-assignment-distributions.tsv \
	$raw_files/$tool/$database/distribution/

	log "emu abundance completed for $subsample $sample $mismatch with database $database"

###############################################################################