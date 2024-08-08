#!/bin/bash
#SBATCH --job-name 0452_genome_assembly_of_phage_polishing_by_phables
#SBATCH --partition=short
#SBATCH --output results/0452_genome_assembly_of_phage_polishing_by_phables/tmp/slurm/%j.out
#SBATCH --error  results/0452_genome_assembly_of_phage_polishing_by_phables/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0452_genome_assembly_of_phage_polishing_by_phables
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    my_assembly_folder=$(grep "my_assembly_folder" $parameters | awk '{print $NF}' )
    fastq_path=$(grep "fastq_path" $parameters | awk '{print $NF}' )
    conda activate phables_v1.3.2
###############################################################################
    log "STARTED SBATCH : $pipeline : $sublist"
###############################################################################
## step-01: runnig phables  tool 

	for i in $(cat $sublist); do
        if [ ! -d $raw_files/$i ] ; then 
        log "STARTED : $pipeline : $i"

        phables run \
        --input $my_assembly_folder/raw_files/$i/*.gfa \
        --reads $data_directory_fastq_path/$i.fastq.gz \
        --threads 10 \
        --longreads 

        log "FINISHED : $pipeline : $i"
        else
        log "ALREADY FINISHED: $pipeline : $i"
        fi
	done 

###############################################################################
    log "FINISHED SBATCH : $pipeline : $sublist"
###############################################################################

