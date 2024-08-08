#!/bin/bash
#SBATCH --job-name 0451_genome_assembly_polishing_for_nanopore_by_medaka
#SBATCH --partition=short
#SBATCH --output results/0451_genome_assembly_polishing_for_nanopore_by_medaka/tmp/slurm/%j.out
#SBATCH --error  results/0451_genome_assembly_polishing_for_nanopore_by_medaka/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0451_genome_assembly_polishing_for_nanopore_by_medaka
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    my_fasta_path=$(grep "my_fasta_path" $parameters | awk '{print $NF}' )
    fastq_path=$(grep "fastq_path" $parameters | awk '{print $NF}' )
###############################################################################
    log "STARTED SBATCH : $pipeline : $sublist"
###############################################################################
## step-01: runnig medaka tool 
    
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate medaka_v1.11.3
	for i in $(cat $sublist); do
        if [ ! -d $raw_files/$i ] ; then 
        log "STARTED : $pipeline : $i"

        medaka_consensus \
        -i $data_directory_fastq_path/$i.fastq.gz \
        -d $my_fasta_path/$i.fasta \
        -o $raw_files/$i

        log "FINISHED : $pipeline : $i"
        else
        log "ALREADY FINISHED: $pipeline : $i"
        fi
	done 
    conda deactivate

###############################################################################
    log "FINISHED SBATCH : $pipeline : $sublist"
###############################################################################

