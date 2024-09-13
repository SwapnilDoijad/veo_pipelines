import argparse
import gzip
from Bio import SeqIO

# Set up argument parsing
parser = argparse.ArgumentParser(description="Count the number of reads greater than a specified length in a gzipped FASTQ file.")
parser.add_argument("-i", "--input", required=True, help="Input file (gzipped FASTQ format, .fastq.gz)")
parser.add_argument("-o", "--output", required=True, help="Output file to write the results")
parser.add_argument("-l", "--length", type=int, default=100, help="Minimum length of reads to count (default: 100 bp)")

args = parser.parse_args()

# Initialize a counter for sequences longer than the specified length
count = 0

# Parse the gzipped input FASTQ file and count sequences longer than the given length
with gzip.open(args.input, "rt") as input_handle:  # "rt" for reading text
    for record in SeqIO.parse(input_handle, "fastq"):
        if len(record.seq) > args.length:
            count += 1

# Write the result to the output file
with open(args.output, "w") as output_handle:
    output_handle.write(f"Number of reads longer than {args.length} bp: {count}\n")

print(f"Number of reads longer than {args.length} bp: {count}")
