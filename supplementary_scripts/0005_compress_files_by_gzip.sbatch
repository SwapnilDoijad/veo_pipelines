#!/bin/bash
###############################################################################
#SBATCH --job-name=0005_compress_files_by_gzip
#SBATCH --partition=standard
#SBATCH --output=results/0005_compress_files_by_gzip/tmp/slurm/%j.err
#SBATCH --error=results/0005_compress_files_by_gzip/tmp/slurm/%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --exclusive
############################################################################### 
    pipeline=0005_compress_files_by_gzip
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    list=$wd/tmp/lists/list.0005_compress_files_by_gzip_000
    in_dir=$(grep my_uncompressed_file_dir $parameters | awk '{print $2}')
    out_dir=$(grep my_compressed_file_dir $parameters | awk '{print $2}')
    source_file_remove=$(grep my_source_file_remove $parameters | awk '{print $2}')

    for i in $(cat $list); do
        if [ ! -f $out_dir/$i.gz ]; then
            log "compressing $i"
            pigz -9 -c $in_dir/$i > $out_dir/$i.gz
            else
            log "$i already compressed"
        fi

        if [ -f $out_dir/$i.gz ] ; then 
                if [ $source_file_remove = "Yes" ]; then
                log "deleting $i"
                rm -rf $in_dir/$i
                fi
            else
            log "failed to compress $i"
        fi
    done
###############################################################################