#!/bin/bash
#SBATCH --job-name 0221_gene_detection_abr_by_AMRFinder
#SBATCH --partition=standard,long
#SBATCH --output results/0221_gene_detection_abr_by_AMRFinder/tmp/slurm/%j.out
#SBATCH --error  results/0221_gene_detection_abr_by_AMRFinder/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-01: preparation
    pipeline=0221_gene_detection_abr_by_AMRFinder
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	sublist=results/$pipeline/tmp/lists/ABC
    fasta_directory=$( grep my_fasta_directory $parameters | awk '{print $2}' )
###############################################################################
## step-02: run amrfinder
    conda activate amrfinder_v4.0.3
    version=$(amrfinder --version)
    database=$(ls /vast/groups/VEO/tools/miniconda3_2024/envs/amrfinder_v$version/share/amrfinderplus/data/ | sort | grep -v latest | tail -1 )
    log "STARTED : $pipeline : sbatch for $sublist"
    
    for fasta in $(cat $sublist); do
        if [ ! -f $raw_files/$fasta.csv ] ; then
            log "running... AMRFinder $version database version $db_version blast for $fasta"
            input_file_type=$(echo $fasta_directory/$fasta | awk -F'.' '{print $NF}')

                if [ "$input_file_type" = "faa" ] ; then

                    (amrfinder \
                    -p $fasta_directory/$fasta \
                    -o $raw_files/$fasta.csv \
                    --threads 10 )> /dev/null 2>&1

                    elif [ "$input_file_type" = "fasta" ] || [ "$input_file_type" = "fa" ] || [ "$input_file_type" = "fna" ]; then

			        (amrfinder \
                    -n $fasta_directory/$fasta \
                    -o $raw_files/$fasta.csv \
                    --threads 10 )> /dev/null 2>&1

                fi

            awk 'FNR>1' $raw_files/$fasta.csv >> $raw_files/tmp/all.txt
            else
            log "ALREADY FINISHED : $pipeline : $fasta"
        fi
    done

    log "ENDED : $pipeline : sbatch for $sublist"
###############################################################################