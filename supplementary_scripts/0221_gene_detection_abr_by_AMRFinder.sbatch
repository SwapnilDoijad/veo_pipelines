#!/bin/bash
#SBATCH --job-name 0221_gene_detection_abr_by_AMRFinder
#SBATCH --partition=standard
#SBATCH --output results/0221_gene_detection_abr_by_AMRFinder/tmp/slurm/%j.out
#SBATCH --error  results/0221_gene_detection_abr_by_AMRFinder/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0221_gene_detection_abr_by_AMRFinder
    wd=results/$pipeline

    sublist=$wd/tmp/lists/ABC
    parameter_file=tmp/parameters/0221_gene_detection_abr_by_AMRFinder.tsv
###############################################################################
## step-02: run amrfinder
    source /home/xa73pav/tools/anaconda3/etc/profile.d/conda.sh
    conda activate amrfinder_v3.11.14
    version=$(amrfinder --version)
    database=$(ls /home/xa73pav/tools/anaconda3/envs/amrfinder_v$version/share/amrfinderplus/data/ | sort | grep -v latest | tail -1 )
    log "STARTED : $pipeline : sbatch for $sublist"

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i.csv ] ; then
            log "running... AMRFinder $version database verssion $db_version blast for $i"
            file_path=$(rg -w "$i" $parameter_file | awk '{print $2}')
            input_file_type=$(echo $file_path | awk -F'.' '{print $NF}')

                if [ "$input_file_type" = "faa" ] ; then

                    (amrfinder \
                    -p $file_path \
                    -o $wd/raw_files/$i.csv \
                    --threads 10 )> /dev/null 2>&1

                    elif [ "$input_file_type" = "fasta" ] || [ "$input_file_type" = "fa" ] || [ "$input_file_type" = "fna" ]; then

			        (amrfinder \
                    -n $file_path \
                    -o $wd/raw_files/$i.csv \
                    --threads 10 )> /dev/null 2>&1

                fi

            awk 'FNR>1' $wd/raw_files/$i.csv >> $wd/tmp/all.txt
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
    done

    log "ENDED : $pipeline : sbatch for $sublist"
###############################################################################