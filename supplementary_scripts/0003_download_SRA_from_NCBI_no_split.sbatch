#!/bin/bash
###############################################################################
#SBATCH --job-name=0003_download_SRA_from_NCBI_no_split
#SBATCH --partition=standard
#SBATCH --output=results/0003_download_SRA_from_NCBI_no_split/tmp/slurm/%j.err
#SBATCH --error=results/0003_download_SRA_from_NCBI_no_split/tmp/slurm/%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
############################################################################### 
    pipeline=0003_download_SRA_from_NCBI_no_split
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    list=$wd/tmp/lists/ABC

        for SRA_id in $(cat $list); do
            if [ ! -f /veodata/02/databases/fastqs/raw_files/"$SRA_id".fastq ] ; then
                ## Download
                log "DOWNLOADING : $SRA_id"
                ( /home/groups/VEO/tools/sratoolkit/v3.0.1/bin/prefetch $SRA_id ) > /dev/null 2>&1 ;

                ## Conversion to fastq
                log "CONVERTING : SRA to fastq : $SRA_id"
                ( /home/groups/VEO/tools/sratoolkit/v3.0.1/bin/fastq-dump \
                --outdir /veodata/02/databases/fastqs/raw_files/ \
                $SRA_id \
                ) > /dev/null 2>&1 ;

                rm -rf $SRA_id

                ## Conversion to fastq F and R
                    # echo "converting SRA to fastq $SRA_id"
                    # ( /home/groups/VEO/tools/sratoolkit/v3.0.1/bin/fastq-dump \
                    # --outdir /veodata/02/databases/fastqs/ \
                    # -split-files /home/swapnil/ncbi/public/sra/$SRA_id.sra \
                    # ) > /dev/null 2>&1 ;

                ## Check for fastq pair
                # if [ -f /veodata/02/databases/fastqs/"$SRA_id"_1.fastq ] && [ -f /veodata/02/databases/fastqs/"$SRA_id"_2.fastq ] ; then
                #     cp /veodata/02/databases/fastqs/"$SRA_id"_1.fastq data/ncbi/raw_files ;
                #     (gzip data/ncbi/raw_files/"$SRA_id"_1.fastq) > /dev/null 2>&1 ;
                #     rm /veodata/02/databases/fastqs/"$SRA_id"_1.fastq ;
                #     cp /veodata/02/databases/fastqs/"$SRA_id"_2.fastq data/ncbi/raw_files/ ;
                #     (gzip data/ncbi/raw_files/"$SRA_id"_2.fastq) > /dev/null 2>&1 ;
                #     rm /veodata/02/databases/fastqs/"$SRA_id"_2.fastq ;
                #     rm /home/swapnil/ncbi/public/sra/$SRA_id.sra ;
                # fi
            else
                echo "$SRA_id already dowloaded"
            fi
        done
###############################################################################