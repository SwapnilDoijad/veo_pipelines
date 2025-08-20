#!/bin/bash
#SBATCH --job-name=0651_phage_clustering_by_vcontact
#SBATCH --partition=standard,long
#SBATCH --output=results/0651_phage_clustering_by_vcontact/tmp/slurm/%j.out
#SBATCH --error=results/0651_phage_clustering_by_vcontact/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## step-00: preparation
    pipeline=0651_phage_clustering_by_vcontact
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    faa_path=$( grep my_faa_path $parameters | awk '{print $2}' )
    database=$( grep my_database $parameters | awk '{print $2}' )
    vcontact_version=$( grep my_vcontact_version $parameters | awk '{print $2}' )
    fasta=$( grep my_fasta_path $parameters | awk '{print $2}' )
    list=list.$pipeline.txt
	log "STARTED: $pipeline -----------------------"
    log "faa_path: $faa_path"
    log "database: $database"
    log "vcontact_version: $vcontact_version"
    log "fasta: $fasta"
    (mkdir $raw_files/results) > /dev/null 2>&1
###############################################################################
	log "STARTED : $pipeline for $sublist" 
###############################################################################
## running vcontact2
    if [ "$vcontact_version" == "v2" ]; then
        if [ ! -f $raw_files/proteins.faa ] ; then 
            for i in $(cat $list); do
                (mkdir $raw_files/$i) > /dev/null 2>&1

                grep ">" $faa_path/$i.faa | sed 's/>//g' | awk '{print $1}' \
                >> $raw_files/$i.1.tmp

                # | sed 's/ /_/g'
                grep ">" $faa_path/$i.faa | sed 's/>//g' | cut -f 2- -d ' ' | sed 's/\,/_/g' | sed "s/\'/_/g" \
                >> $raw_files/$i.3.tmp

                total_cds=$(wc -l $raw_files/$i.1.tmp | awk '{print $1}')
                for i2 in `seq $total_cds`; do 
                    echo "$i" >> $raw_files/$i.2.tmp
                done

                paste $raw_files/$i.1.tmp \
                $raw_files/$i.2.tmp \
                $raw_files/$i.3.tmp \
                > $raw_files/$i/$i.for_vcontact2.csv

                cat $raw_files/$i/$i.for_vcontact2.csv \
                >> $raw_files/for_vcontact2.csv

                cat $faa_path/$i.faa >> $raw_files/proteins.faa

                (rm -rf $raw_files/$i ) > /dev/null 2>&1
            done
            sed -i '1 i\protein_id,contig_id,keywords' $raw_files/for_vcontact2.csv
            sed -i 's/\t/,/g' $raw_files/for_vcontact2.csv
        fi

        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
        conda activate vcontact2_p310
        log "RUNNING : vcontact2"
        
        vcontact2 \
        -r $raw_files/proteins.faa \
        --db $database \
        -p $raw_files/for_vcontact2.csv \
        --c1-bin /home/groups/VEO/tools/anaconda3/bin/cluster_one-1.0.jar \
        -o $raw_files/results \
        -t $SLURM_CPUS_PER_TASK \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/vcontact2.run.tsv

    fi

###############################################################################
## running vcontact3

    if [ "$vcontact_version" == "v3" ]; then

        source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
        conda activate vcontact3_3.0.5-0 
        log "RUNNING : vcontact3"

        vcontact3 \
        run \
        -n $fasta \
        -e graphml cytoscape \
        --db-path /veodata/03/databases/vcontact3/v20250820 \
        -o $raw_files/results \
        -t $SLURM_CPUS_PER_TASK \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/vcontact3.run.tsv 

        # realms=("Monodnaviria" "Duplodnaviria" "Adnaviria" "Varidnaviria")
        # for realm in "${realms[@]}"; do
        #     vcontact3 \
        #     run \
        #     -n $fasta \
        #     -e graphml cytoscape \
        #     --db-path /veodata/03/databases/vcontact3/v20250721 \
        #     -o $raw_files/results \
        #     --default-realm $realm \
        #     -t $SLURM_CPUS_PER_TASK \
        #     & my_pid=$!
        #     get_resource_stat $my_pid $wd/tmp/resource_log/vcontact3.run.tsv
        # done
    fi

###############################################################################
	log "FINISHED : $pipeline for $sublist" && clean
###############################################################################
        