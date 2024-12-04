#!/bin/bash
#SBATCH --job-name 0050_genome_assembly_QC_by_quast
#SBATCH --partition=short
#SBATCH --output results/0050_genome_assembly_QC_by_quast/tmp/slurm/%j.out.0050_genome_assembly_QC_by_quast
#SBATCH --error results/0050_genome_assembly_QC_by_quast/tmp/slurm/%j.err.0050_genome_assembly_QC_by_quast
#SBATCH --mem=20G
#SBATCH --cpus-per-task=10
#-- Command section ------------------------
pipeline=0050_genome_assembly_QC_by_quast
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
fasta_directory=$(grep -w "my_fasta_directory" $parameters | awk -F'\t' '{print $2}')

    for i in $(cat $sublist); do 
        if [ ! -f results/0050_genome_assembly_QC_by_quast/raw_files/$i/transposed_report.tsv ]; then
            log "RUNNING : quast for $i"
            (mkdir  results/0050_genome_assembly_QC_by_quast/raw_files/$i) > /dev/null 2>&1
            python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
            -o results/0050_genome_assembly_QC_by_quast/raw_files/$i \
            --silent -t $SLURM_CPUS_PER_TASK $fasta_directory/"$i".fasta
            else
            log "ALREADY FINISHED : quast for $i"
        fi
    done 

    for i in $(cat $sublist); do 
        if [ -s results/0050_genome_assembly_QC_by_quast/raw_files/$i/transposed_report.tsv ] ; then
            tail -1 results/0050_genome_assembly_QC_by_quast/raw_files/$i/transposed_report.tsv > results/0050_genome_assembly_QC_by_quast/raw_files/$i/transposed_report.tsv.tmp
        else
            echo -e "$i\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0" > results/0050_genome_assembly_QC_by_quast/raw_files/$i/transposed_report.tsv.tmp
        fi
    done

    for i in $(cat $sublist); do 
        while [ ! -f "$wd/raw_files/$i/transposed_report.tsv.tmp" ] ; do
            log "WAITING : quast to finish $i"
            sleep 60
        done
        log "FINISHED : quast for $i"
        cat $wd/raw_files/$i/transposed_report.tsv.tmp >> $wd/summary.tsv ;
    done 