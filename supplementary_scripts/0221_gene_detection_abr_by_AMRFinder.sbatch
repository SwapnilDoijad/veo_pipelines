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
	sublist=$wd/tmp/lists/ABC
    fasta_directory=$( grep my_fasta_directory $parameters | awk '{print $2}' )
###############################################################################
## step-02: run amrfinder
    conda activate amrfinder_v4.0.3
    version=$(amrfinder --version)
    database=$(ls /vast/groups/VEO/tools/miniconda3_2024/envs/amrfinder_v$version/share/amrfinderplus/data/ | sort | grep -v latest | tail -1 )
    log "STARTED : $pipeline : sbatch for $sublist"
    
    input_file_type=$(ls $fasta_directory | head -1 |  awk -F'.' '{print $NF}')
    for fasta in $(cat $sublist); do
        if [ ! -f $raw_files/$fasta.csv ] ; then
            log "running... AMRFinder $version database version $db_version blast for $fasta"


                if [ "$input_file_type" = "faa" ] ; then
                    log "Input file type detected as .faa"
                    (amrfinder \
                    -p $fasta_directory/$fasta \
                    -o $raw_files/$fasta.csv \
                    --threads 10 )> /dev/null 2>&1

                    elif [ "$input_file_type" = "fasta" ] || [ "$input_file_type" = "fa" ] || [ "$input_file_type" = "fna" ]; then
                    log "Input file type detected as .fasta/.fa/.fna"
			        (amrfinder \
                    -n $fasta_directory/$fasta \
                    -o $raw_files/$fasta.csv \
                    --threads 10 )> /dev/null 2>&1

                fi

            awk 'FNR>1' $raw_files/$fasta.csv >> $raw_files/tmp/all.txt
            
            sed "s/^/$i\t/g"  $raw_files/$i.fasta.csv \
            | sed "0,/$i/s/$i/id/" \
            > $raw_files/$i.fasta.tsv

            else
            log "ALREADY FINISHED : $pipeline : $fasta"
        fi
    done

    sed '/Method/d' $raw_files/*.fasta.tsv \
    >> $raw_files/tmp/combined.fasta.tsv

    log "ENDED : $pipeline : sbatch for $sublist"
###############################################################################