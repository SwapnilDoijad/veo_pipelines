#!/bin/bash
#SBATCH --job-name 0063_identification_fasta_by_kraken2
#SBATCH --partition=long
#SBATCH --output results/0063_identification_fasta_by_kraken2/tmp/slurm/%j.out.0063_identification_fasta_by_kraken2.txt
#SBATCH --error results/0063_identification_fasta_by_kraken2/tmp/slurm/%j.err.0063_identification_fasta_by_kraken2.txt
#SBATCH --mem=100G
#SBATCH --cpus-per-task=80
###############################################################################
## header
    start_time=$(date +"%Y%m%d_%H%M%S")
###############################################################################
    sublist=results/0063_identification_fasta_by_kraken2/tmp/lists/ABC
    fasta_file_path=XYZ
    number_of_lines=$(cat $sublist | wc -l )
    echo "kraken2 $sublist:: running"

    for F1 in $(cat $sublist ); do
        if [ ! -f results/0063_identification_fasta_by_kraken2/raw_files/$F1.report.txt ] ; then 
            current_line_number=$(grep -n -w "$F1" $sublist | awk -F':' '{print $1}')
            echo "kraken2 for $F1 ($current_line_number/$number_of_lines): running"

            /home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
            --db /work/groups/VEO/databases/kraken2/v20180901 \
            --minimum-hit-groups 1 --output - --threads 80 --report results/0063_identification_fasta_by_kraken2/raw_files/$F1.report.txt \
            --use-mpa-style --use-names $fasta_file_path/$F1.fasta

            id=$(grep "|s_" results/0063_identification_fasta_by_kraken2/raw_files/$F1.report.txt | sort -t $'\t' -k2,2nr | awk '{print $1}' | head -1 )
            if [ -z $id ] ; then 
                id=$(grep "|g_" results/0063_identification_fasta_by_kraken2/raw_files/$F1.report.txt | sort -t $'\t' -k2,2nr | awk '{print $1}' | head -1 )
            fi
            echo -e "$F1\t$id" >> results/0063_identification_fasta_by_kraken2/report.ABC.tsv
            echo "kraken2 for $F1: finished"
            else
            echo "kraken2 for $F1: already finished"
        fi 
    done

    echo "kraken2 $sublist:: finished"

###############################################################################
## footer
    end_time=$(date +"%Y%m%d_%H%M%S")
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/time_calculations.sh "$start_time" "$end_time"
###############################################################################