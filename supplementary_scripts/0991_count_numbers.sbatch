#!/bin/bash
###############################################################################
#SBATCH --job-name=04_0991_calculate_abundance_from_fastq
#SBATCH --partition=interactive
#SBATCH --output results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.count
#SBATCH --error  results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.count
#SBATCH --cpus-per-task=24
###############################################################################
## read options for the inputfile 
pipeline=0991_calculate_abundance_from_fastq
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
max_blast_mismatch=my_blast_mismatch

echo "running count_numbers.RC for barcode barcode_RC"
echo -e "read_id\tmismtach\tmismtach-with_other_reads" \
> $raw_files/blast_results/barcode_FR.barcode_RC.QC.fastq.fasta.best_hits.subsample.max_"$max_blast_mismatch".tsv  

# Define a function to process each read_id
process_read() {
    local read_id="$1"
    local max_blast_mismatch="$2"
    local blast_file="results/0991_calculate_abundance_from_fastq/raw_files/blast_results/barcode_FR.barcode_RC.QC.fastq.fasta.subsample.tsv"
    local best_hits_file="results/0991_calculate_abundance_from_fastq/raw_files/blast_results/barcode_FR.barcode_RC.QC.fastq.fasta.best_hits.subsample.max_"$max_blast_mismatch".tsv"

    best_hit=$(grep "$read_id" "$blast_file" | sort -n -k6,6 | awk -v max_m="$max_blast_mismatch" '$6 <= max_m {print $1, $2; exit}')

    if [[ -n "$best_hit" ]]; then
        echo "$best_hit" >> "$best_hits_file"
        else
        touch "$best_hits_file"
    fi
    }

# Export the function so that it's available to parallel
export -f process_read

# Use parallel to process read_ids in parallel
cat $raw_files/read_ids_extracted/list.barcode_FR.barcode_RC.read_ids.subsample.txt | awk '{print $1}' | sed 's/@//g' | /home/groups/VEO/tools/parallel/v20230822/src/parallel process_read {} "$max_blast_mismatch"

## because of parallel process sometimes blank line occurs, remove those lines
sed -i '/^$/d' $raw_files/blast_results/barcode_FR.barcode_RC.QC.fastq.fasta.best_hits.subsample.max_"$max_blast_mismatch".tsv  ; 

## count the number of 
awk -F' ' '{print $2}' $raw_files/blast_results/barcode_FR.barcode_RC.QC.fastq.fasta.best_hits.subsample.max_"$max_blast_mismatch".tsv  \
| sort | uniq -c | awk '{print $2, $1}' | tr ' ' '\t' \
> $raw_files/count/barcode_FR.barcode_RC.QC.fastq.fasta.best_hits.count.subsample.max_"$max_blast_mismatch".tsv

echo "finished: running count_numbers.RC for barcode barcode_RC"
