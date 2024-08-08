#!/bin/bash
###############################################################################
#SBATCH --job-name 0007_basecalling
#SBATCH --partition=long
#SBATCH --output tmp/slurm/0007_basecalling.slurm.out.%j
#SBATCH --error  tmp/slurm/0007_basecalling.slurm.err.%j
#SBATCH --ntasks=1
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
## basecalling
        ## create necessary directories 
        ( rm /scratch/fast5/$file ) > /dev/null 2>&1
        ( rm /scratch/basecalled/$file ) > /dev/null 2>&1
        ( mkdir -p /scratch/fast5/$file ) > /dev/null 2>&1
        ( mkdir -p /scratch/basecalled/$file ) > /dev/null 2>&1

        echo "copying $file to /scratch/fast5/"
        cp $dir_path/fast5/$file /scratch/fast5/$file/

        ## run guppy cpu/gpu-based basecaller
        ## /home/groups/VEO/tools/ont-guppy/v6.5.7_gpu/bin/guppy_basecaller \
        /home/groups/VEO/tools/ont-guppy/v6.5.7_cpu/bin/guppy_basecaller \
        -i /scratch/fast5/$file \
        -s /scratch/basecalled \
        --flowcell FLO-MIN114 \
        --kit SQK-NBD114-96 
       # -c $my_tool_path/data/dna_r10.4.1_450bps_fast.cfg

        (mkdir /scratch/basecalled/guppy_log ) > /dev/null 2>&1
        (mv /scratch/basecalled/$file/*.log /scratch/basecalled/guppy_log) > /dev/null 2>&1

        rm -r /scratch/fast5/$file
        rm -r /scratch/basecalled/$file

        echo "basecalling finished for $file"
###############################################################################

