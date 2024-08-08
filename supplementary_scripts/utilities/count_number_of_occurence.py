import argparse

parser = argparse.ArgumentParser(description="count BLAST results for DNA sequence reads")
parser.add_argument("-b", "--barcode", required=True, help="Barcode value")
args = parser.parse_args()

barcode = args.barcode
input_file = f"results/blast_search_of_reads/blast_results/{barcode}.10.fastq.fasta.tsv"
output_file = f"results/blast_search_of_reads/count/{barcode}.10.fastq.fasta.txt"

reads_to_best_hits = {}

with open(input_file, "r") as blast_results:
    for line in blast_results:
        if line.startswith("#"):
            continue  # Skip comment lines
        columns = line.strip().split("\t")
        read = columns[1]
        if read not in reads_to_best_hits or float(columns[4]) < reads_to_best_hits[read][0]:
            reads_to_best_hits[read] = (float(columns[4]), columns[0])

with open(output_file, "w") as output:
    for read, (score, hit) in reads_to_best_hits.items():
        output.write(f"{read} {hit}\n")

