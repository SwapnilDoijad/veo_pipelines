#!/bin/bash
###############################################################################
#SBATCH --job-name 0008_step02_demultiplexing_nanopore_basecalling_gpu
#SBATCH --partition=gpu
#SBATCH --output results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.out.02_fast5_to_basecall
#SBATCH --error  results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.err.02_fast5_to_basecall
#SBATCH --gres=gpu:1
###############################################################################
## step-00: preparation
	pipeline=0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    module load nvidia/cuda/11.7 
###############################################################################
## basecalling

    log "STARTED SBATCH : 02_fast5_to_basecall"
        ( mkdir -p $raw_files/02_fast5_to_basecall/all_files ) > /dev/null 2>&1
        ( mkdir -p $raw_files/02_fast5_to_basecall/tmp ) > /dev/null 2>&1
        ( mkdir -p $raw_files/02_fast5_to_basecall/all_fastqs ) > /dev/null 2>&1

        ## run guppy gpu/gpu-based basecaller
            /home/groups/VEO/tools/ont-guppy/v6.5.7_gpu/bin/guppy_basecaller \
            -i $raw_files/01_pod5_fast5 \
            -s $raw_files/02_fast5_to_basecall/all_files \
            --flowcell FLO-MIN114 \
            --kit SQK-NBD114-96 \
            -x 'cuda:0'
            # -c $my_tool_path/data/dna_r10.4.1_450bps_fast.cfg

        # (cp $raw_files/02_fast5_to_basecall/all_files/$file/pass/*.fastq $raw_files/02_fast5_to_basecall/all_fastqs/ ) > /dev/null 2>&1
        # (mkdir $raw_files/02_fast5_to_basecall/all_fastqs/guppy_log ) > /dev/null 2>&1
        # (mv $raw_files/02_fast5_to_basecall/all_files/$file/*.log $raw_files/02_fast5_to_basecall/all_fastqs/guppy_log) > /dev/null 2>&1
    
    log "FINISHED SBATCH : 02_fast5_to_basecall"
###############################################################################
 