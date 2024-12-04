#!/bin/bash
###############################################################################
#SBATCH --job-name 0007_demultiplexing_nanopore_basecalling_by_guppy_cpu
#SBATCH --partition=standard
#SBATCH --output tmp/slurm/0007_demultiplexing_nanopore_basecalling_by_guppy_cpu.sbatch.slurm.out.%j
#SBATCH --error  tmp/slurm/0007_demultiplexing_nanopore_basecalling_by_guppy_cpu.sbatch.slurm.err.%j
###############################################################################
## read options for the inputfile

    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -file)
                file="$2"
                shift 2
                ;;
            -dir_path)
                dir_path="$2"
                shift 2
                ;;
            *)
                echo "Invalid flag: $1"
                exit 1
                ;;
        esac
    done

    # Check if required flags are provided
    if [[ -z $file || -z $dir_path ]]; then
        echo "Missing required flags!"
        exit 1
    fi

    # Run your desired commands using the provided file and path
    echo "File: $file"
    echo "Path: $dir_path"

###############################################################################
## demultiplexing 

        ## create necessary directories 
        ( mkdir $dir_path/pod5_fast5_basecalled_guppy_cpu_demultiplexed/$file ) > /dev/null 2>&1

        ## run guppy cpu baracoder
        /home/groups/VEO/tools/ont-guppy/v6.5.7_cpu/bin/guppy_barcoder \
        -t 10 \
        -i $dir_path/pod5_fast5_basecalled_guppy_cpu/$file/pass/ \
        -s $dir_path/pod5_fast5_basecalled_guppy_cpu_demultiplexed/$file/ \
        --barcode_kits SQK-NBD114-96 --enable_trim_barcodes --trim_adapters

        echo "demultiplexing finished for $file"
###############################################################################
 
