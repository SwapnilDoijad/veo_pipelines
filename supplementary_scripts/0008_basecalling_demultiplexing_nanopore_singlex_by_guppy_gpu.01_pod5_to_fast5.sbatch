#!/bin/bash
#SBATCH --job-name 0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu
#SBATCH --partition=interactive
#SBATCH --output results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.out.01_pod5_fast5
#SBATCH --error  results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.err.01_pod5_fast5
#SBATCH --cpus-per-task=80
#SBATCH --mem=200G
###############################################################################
## step-00: preparation
	pipeline=0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    pod5_file_path=$(grep my_pod5_file_path $parameters | awk -F'\t' '{print $2}' )
###############################################################################
## step-01: run pod5 converter
	source /home/groups/VEO/tools/pod5/v0.2.2/bin/activate
    for i in $(cat $sublist); do
		log "STARTED : $pipeline : $i : pod5 to fast5 conversion"
		pod5 convert to_fast5 $pod5_file_path/$i.pod5 -t $SLURM_CPUS_PER_TASK -o $raw_files/01_pod5_fast5/
		log "FINISHED : $pipeline : $i : pod5 to fast5 conversion"
	done
###############################################################################