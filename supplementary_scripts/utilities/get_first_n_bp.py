## python3 get_first_n_bp.py -i input.fasta -o output.fasta -n 45 -p 8

import argparse
from Bio import SeqIO
from multiprocessing import Pool

# Function to extract the first n base pairs from a sequence
def extract_first_n_bp(sequence, n):
    return sequence[:n]

# Function to process a single sequence record
def process_sequence(record):
    first_n_bp = extract_first_n_bp(record.seq, args.length)
    return f'>{record.id}\n{first_n_bp}\n'

# Create argument parser
parser = argparse.ArgumentParser(description='Extract the first N base pairs from each sequence in a multifasta file.')

# Define input and output file arguments
parser.add_argument('-i', '--input', required=True, help='Input multifasta file')
parser.add_argument('-o', '--output', required=True, help='Output multifasta file')
parser.add_argument('-n', '--length', type=int, default=50, help='Number of base pairs to extract (default: 50)')
parser.add_argument('-p', '--processes', type=int, default=4, help='Number of processes to use (default: 4)')

# Parse command-line arguments
args = parser.parse_args()

# Open the output file for writing
with open(args.output, 'w') as out_file:
    # Iterate through each sequence in the multifasta file
    records = list(SeqIO.parse(args.input, 'fasta'))
    
    # Create a pool of processes for parallel processing
    with Pool(processes=args.processes) as pool:
        results = pool.map(process_sequence, records)
        
    # Write the extracted sequences to the output file
    out_file.writelines(results)

print(f'First {args.length} base pairs from each sequence extracted to {args.output}')
