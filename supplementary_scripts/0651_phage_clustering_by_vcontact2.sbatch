#!/bin/bash
#SBATCH --job-name=0651_phage_clustering_by_vcontact2
#SBATCH --partition=short,long
#SBATCH --output=results/0651_phage_clustering_by_vcontact2/tmp/slurm/%j.out
#SBATCH --error=results/0651_phage_clustering_by_vcontact2/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################
## step-00: preparation
    pipeline=0651_phage_clustering_by_vcontact2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    faa_path=$( grep my_faa_path $parameters | awk '{print $2}' )
    database=$( grep my_database $parameters | awk '{print $2}' )
    list=list.$pipeline.txt
	log "STARTED: $pipeline -----------------------"
    log "faa_path: $faa_path"
    log "database: $database"
###############################################################################
if [ ! -f results/0651_phage_clustering_by_vcontact2/raw_files/proteins.faa ] ; then 
    for i in $(cat $list); do
        (mkdir results/0651_phage_clustering_by_vcontact2/raw_files/$i) > /dev/null 2>&1

        grep ">" $faa_path/$i.faa | sed 's/>//g' | awk '{print $1}' \
        >> results/0651_phage_clustering_by_vcontact2/raw_files/$i.1.tmp

        # | sed 's/ /_/g'
        grep ">" $faa_path/$i.faa | sed 's/>//g' | cut -f 2- -d ' ' | sed 's/\,/_/g' | sed "s/\'/_/g" \
        >> results/0651_phage_clustering_by_vcontact2/raw_files/$i.3.tmp

        total_cds=$(wc -l results/0651_phage_clustering_by_vcontact2/raw_files/$i.1.tmp | awk '{print $1}')
        for i2 in `seq $total_cds`; do 
            echo "$i" >> results/0651_phage_clustering_by_vcontact2/raw_files/$i.2.tmp
        done

        paste results/0651_phage_clustering_by_vcontact2/raw_files/$i.1.tmp \
        results/0651_phage_clustering_by_vcontact2/raw_files/$i.2.tmp \
        results/0651_phage_clustering_by_vcontact2/raw_files/$i.3.tmp \
        > results/0651_phage_clustering_by_vcontact2/raw_files/$i/$i.for_vcontact2.csv

        cat results/0651_phage_clustering_by_vcontact2/raw_files/$i/$i.for_vcontact2.csv \
        >> results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv

        cat $faa_path/$i.faa >> results/0651_phage_clustering_by_vcontact2/raw_files/proteins.faa

        (rm -rf results/0651_phage_clustering_by_vcontact2/raw_files/$i ) > /dev/null 2>&1
    done
    sed -i '1 i\protein_id,contig_id,keywords' results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv
    sed -i 's/\t/,/g' results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv
fi

###############################################################################
## running vcontact2
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
    conda activate vcontact2_p310
    (mkdir $raw_files/results) > /dev/null 2>&1

    log "RUNNING : vcontact2"
    
    vcontact2 \
    -r results/0651_phage_clustering_by_vcontact2/raw_files/proteins.faa \
    --db $database \
    -p results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv \
    --c1-bin /home/groups/VEO/tools/anaconda3/bin/cluster_one-1.0.jar \
    -o results/0651_phage_clustering_by_vcontact2/raw_files/results \
    -t $SLURM_CPUS_PER_TASK

    log "FINISHED: vcontact2"

###############################################################################

