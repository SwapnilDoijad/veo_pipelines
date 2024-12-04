#!/bin/bash
#SBATCH --job-name 0052_metagenome_assembly_by_fly
#SBATCH --partition=short
#SBATCH --output results/0052_metagenome_assembly_by_fly/tmp/slurm/%j.out.0052_metagenome_assembly_by_fly
#SBATCH --error results/0052_metagenome_assembly_by_fly/tmp/slurm/%j.err.0052_metagenome_assembly_by_fly
#SBATCH --mem=200G
#SBATCH --cpus-per-task=50
#-- Command section ------------------------

source /home/groups/VEO/tools/anaconda3_2/etc/profile.d/conda.sh 
conda activate fly_v2.9.2

sublist=results/0052_metagenome_assembly_by_fly/tmp/lists/ABC
fastq_file_path=XYZ


    for F1 in $(cat $sublist); do
        if [ ! -f results/0052_metagenome_assembly_by_fly/raw_files/$F1/assembly.fasta ]; then 
            echo "running fly-assembler for $F1"
            flye --meta -t 40 \
            --nano-raw $fastq_file_path/$F1.fastq.gz \
            --out-dir results/0052_metagenome_assembly_by_fly/raw_files/$F1
            echo "The fly-assembler for $F1 is finished"
            else
            echo "ALREADY FINISHED: the fly-assembler for $F1"
        fi 
    done
