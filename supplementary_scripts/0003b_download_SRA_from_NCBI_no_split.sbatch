#!/bin/bash
###############################################################################
#SBATCH --job-name 0003b_download_SRA_from_NCBI_no_split
#SBATCH --partition=standard
#SBATCH --output tmp/slurm/%j.err.0003b_download_SRA_from_NCBI_no_split
#SBATCH --error  tmp/slurm/%j.out.0003b_download_SRA_from_NCBI_no_split
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
###############################################################################
## read options for the inputfile

list=tmp/lists/ABC

    echo "running $ABC"
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate parallel-fastq-dump_v3.0.3

    for SRA_id in $(cat $list); do
        if [ ! -f /work/groups/VEO/databases/fastqs/raw_files/"$SRA_id".fastq ] ; then
            echo "downloading $SRA_id"
            parallel-fastq-dump --sra-id $SRA_id \
            --threads 40 \
            -T /work/groups/VEO/databases/fastqs \
            --outdir /work/groups/VEO/databases/fastqs/raw_files 
            else
            echo "$SRA_id already dowloaded"
        fi
    done 