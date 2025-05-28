#!/bin/bash
#SBATCH --job-name 0551_genome_assembly_QC_with_ref_by_quast
#SBATCH --partition=standard
#SBATCH --output results/0551_genome_assembly_QC_with_ref_by_quast/tmp/slurm/%j.out.0551_genome_assembly_QC_with_ref_by_quast
#SBATCH --error results/0551_genome_assembly_QC_with_ref_by_quast/tmp/slurm/%j.err.0551_genome_assembly_QC_with_ref_by_quast
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
#-- Command section ------------------------

pipeline=0551_genome_assembly_QC_with_ref_by_quast
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
fasta_path=XYZ

    for i in $(cat $sublist); do 
        if [ ! -f $wd/raw_files/$i/transposed_report.tsv ]; then
            log "RUNNING : quast for $i"
            (mkdir  $wd/raw_files/$i) > /dev/null 2>&1
            # reference=$(ls $wd/all_fasta/$i/*.fasta | head -1 )
            # echo "ref $reference"
            python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
            -r $wd/all_fasta/$i/*.fasta \
            -o $raw_files/$i \
            --nanopore data/fastq/$i.fastq.gz \
            --silent -t 40 $wd/all_fasta/$i/*.fasta
            else
            log "ALREADY FINISHED : quast for $i"
        fi
    done 
