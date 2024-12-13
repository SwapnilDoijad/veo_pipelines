#!/bin/bash
###############################################################################
#SBATCH --job-name=0003b_download_SRA_from_NCBI_no_split
#SBATCH --partition=standard
#SBATCH --output=results/0003b_download_SRA_from_NCBI_no_split/tmp/slurm/%j.err
#SBATCH --error=results/0003b_download_SRA_from_NCBI_no_split/tmp/slurm/%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
###############################################################################
## read options for the inputfile
    pipeline=0003b_download_SRA_from_NCBI_no_split
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    list=$wd/tmp/lists/ABC

    echo "running $ABC"
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh \
    && mamba activate parallel-fastq-dump_v0.6.7-0
    # && conda activate parallel-fastq-dump_v3.0.3


    for SRA_id in $(cat $list); do
        if [ ! -f /veodata/02/databases/fastqs/raw_files/"$SRA_id".fastq ] ; then
            echo "downloading $SRA_id"
            parallel-fastq-dump \
            --sra-id $SRA_id \
            --threads 40 \
            --tmpdir /veodata/02/databases/fastqs \
            --outdir /veodata/02/databases/fastqs/raw_files 
            else
            echo "$SRA_id already dowloaded"
        fi
    done 

###############################################################################