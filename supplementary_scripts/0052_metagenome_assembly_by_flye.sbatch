#!/bin/bash
#SBATCH --job-name 0052_metagenome_assembly_by_flye
#SBATCH --partition=interactive
#SBATCH --output results/0052_metagenome_assembly_by_flye/tmp/slurm/%j.out.0052_metagenome_assembly_by_flye
#SBATCH --error results/0052_metagenome_assembly_by_flye/tmp/slurm/%j.err.0052_metagenome_assembly_by_flye
#SBATCH --mem=100G
#SBATCH --cpus-per-task=20
#-- Command section ------------------------

source /home/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
conda activate flye_v2.9.2

sublist=results/0052_metagenome_assembly_by_flye/tmp/lists/ABC
fastq_file_path=XYZ


    for F1 in $(cat $sublist); do
        if [ ! -f results/0052_metagenome_assembly_by_flye/raw_files/$F1/assembly.fasta ]; then 
            echo "running flye-assembler for $F1"
            flye --meta -t 40 \
            --nano-raw $fastq_file_path/$F1.fastq.gz \
            --out-dir results/0052_metagenome_assembly_by_flye/raw_files/$F1
            echo "The flye-assembler for $F1 is finished"
            else
            echo "ALREADY FINISHED: the flye-assembler for $F1"
        fi 
    done
