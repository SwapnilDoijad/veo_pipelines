#!/bin/bash
#SBATCH --job-name 0053_metagenome_assembly_by_raven
#SBATCH --partition=long
#SBATCH --output results/0053_metagenome_assembly_by_raven/tmp/slurm/0053_metagenome_assembly_by_raven.%j.out
#SBATCH --error results/0053_metagenome_assembly_by_raven/tmp/slurm/0053_metagenome_assembly_by_raven.%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=50
#-- Command section ------------------------

source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
conda activate raven_v1.8.3

sublist=results/0053_metagenome_assembly_by_raven/tmp/lists/ABC
fastq_file_path=XYZ

    for F1 in $(cat $sublist); do
        echo "running raven-assembler for $F1"
        mkdir results/0053_metagenome_assembly_by_raven/raw_files/$F1

        raven -t 40 \
        $fastq_file_path/$F1.fastq.gz \
        > results/0053_metagenome_assembly_by_raven/raw_files/$F1/$F1.fasta
        echo "The raven-assembler for $F1 is finished"
	done