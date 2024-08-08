#!/bin/bash
#SBATCH --job-name 0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta
#SBATCH --partition=interactive
#SBATCH --output results/0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta/tmp/slurm/%j.out
#SBATCH --error  results/0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    wd=results/$pipeline

    sublist=$wd/tmp/lists/ABC
###############################################################################
## step-01: runnig Shasta tool 
	for i in $(cat $sublist); do

        if [ ! -f $wd/raw_files/$i/Assembly.fasta ] ; then 
            log "STARTED : $pipeline : $i"
            gzip -dk $data_directory_fastq_path/$i.fastq.gz
            
            /home/groups/VEO/tools/shasta/v0.11.1/shasta-Linux-0.11.1 \
            --input $data_directory_fastq_path/$i.fastq \
            --config /home/groups/VEO/tools/shasta/v0.11.1/Nanopore-May2020.modified_for_phage_by_Swapnil \
            --assemblyDirectory $wd/raw_files/$i 

            rm $data_directory_fastq_path/$i.fastq
            log "FINISHED : $pipeline : $i"
        fi

        if ! grep -qw "$i" $raw_files/$i/assembly_stat.txt ; then
            python3 $suppl_scripts/utilities/get_fasta_length.py \
            -i $raw_files/$i/Assembly.fasta \
            | sed "s/^/$i\t/g" >> $raw_files/$i/assembly_stat.txt
        fi

	done 

###############################################################################


