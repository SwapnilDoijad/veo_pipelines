#!/bin/bash
###############################################################################
#SBATCH --job-name 0008_demultiplexing_nanopore_basecalling_by_guppy_gpu
#SBATCH --partition=gpu-test
#SBATCH --output results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.out.03_basecall_to_demultiplex
#SBATCH --error results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/tmp/slurm/%j.err.03_basecall_to_demultiplex
#SBATCH --gres=gpu:1
###############################################################################
## step-00: preparation
	pipeline=0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    module load nvidia/cuda/11.7 
###############################################################################
## demultiplexing 

    log "STARTED : SBATCH : $pipeline : demultiplexing"
    if [ ! -d results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/03_basecall_to_demultiplex ]; then 
        ( mkdir -p results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/03_basecall_to_demultiplex ) > /dev/null 2>&1
        ## run guppy gpu baracoder
        echo "demultiplexing started for $file"
        /home/groups/VEO/tools/ont-guppy/v6.5.7_gpu/bin/guppy_barcoder \
        -t 10 -x 'cuda:all' \
        -i $raw_files/02_fast5_to_basecall/pass/ \
        -s $raw_files/03_basecall_to_demultiplex/ \
        --barcode_kits SQK-NBD114-96 --enable_trim_barcodes --trim_adapters
        log "FINISHED : $pipeline : demultiplexing"
        else
        log "ALREADY FINISHED : $pipeline : demultiplexing"
    fi

    log "FINISHED : SBATCH : $pipeline : demultiplexing"
###############################################################################
