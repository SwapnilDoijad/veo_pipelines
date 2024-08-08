#!/bin/bash
###############################################################################
#SBATCH --job-name count_rhizo
#SBATCH --partition=long
#SBATCH --output results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.out.count_rhizo
#SBATCH --error  results/0991_calculate_abundance_from_fastq/tmp/slurm/%j.err.count_rhizo
#SBATCH --cpus-per-task=80
###############################################################################
## read options for the inputfile

echo "running count_rhizo_numbers.RC for barcode barcode_RC"
echo -e "read_id\tmismtach\tmismtach-with_other_reads" \
> results/0991_calculate_abundance_from_fastq/blast_results/barcode.barcode_RC.10.fastq.fasta.rhizo.best_hits.subsample.tsv 

# Define a function to process each read_id
process_read() {
    read_id="$1"
    # total_reads=$(wc -l results/0991_calculate_abundance_from_fastq/tmp/lists/list.barcode.barcode_RC.read_ids.subsample.txt | awk '{print $1}')
	# current_read_number=$(grep -n "$read_id" results/0991_calculate_abundance_from_fastq/tmp/lists/list.barcode.barcode_RC.read_ids.subsample.txt | awk -F':' '{print $1}')
	# echo "processing reads $current_read_number/$total_reads" ;
    best_hit=$(grep "$read_id" results/0991_calculate_abundance_from_fastq/blast_results/barcode.barcode_RC.10.fastq.fasta.rhizo.subsample.tsv | sort -n -k6,6 | awk '{print $1, $2}' | head -1)
    mismatches=$(grep "$read_id" results/0991_calculate_abundance_from_fastq/blast_results/barcode.barcode_RC.10.fastq.fasta.rhizo.subsample.tsv | sort -n -k6,6 | awk '{print $6}' | tr '\n' '\t')
    echo "$best_hit $mismatches" >> results/0991_calculate_abundance_from_fastq/blast_results/barcode.barcode_RC.10.fastq.fasta.rhizo.best_hits.subsample.tsv 
}

# Export the function so that it's available to parallel
export -f process_read

# Use parallel to process read_ids in parallel
cat results/0991_calculate_abundance_from_fastq/tmp/lists/list.barcode.barcode_RC.read_ids.subsample.txt | awk '{print $1}' | sed 's/@//g' | /home/groups/VEO/tools/parallel/v20230822/src/parallel process_read {}

## because of parallel process sometimes blank line occurs, remove those lines
sed -i '/^$/d' results/0991_calculate_abundance_from_fastq/blast_results/barcode.barcode_RC.10.fastq.fasta.rhizo.best_hits.subsample.tsv ; 

## count_rhizo the number of 
awk '{print $2}' results/0991_calculate_abundance_from_fastq/blast_results/barcode.barcode_RC.10.fastq.fasta.rhizo.best_hits.subsample.tsv | sort | uniq -c | awk '{print $2, $1}' | tr ' ' '\t' > results/0991_calculate_abundance_from_fastq/count/barcode.barcode_RC.10.fastq.fasta.rhizo.best_hits.count.subsample.tsv

echo "finished: running count_rhizo_numbers.RC for barcode barcode_RC"
