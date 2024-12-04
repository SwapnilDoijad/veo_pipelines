import argparse
from itertools import product

# Define a function to expand ambiguous bases
def expand_ambiguous_bases(primer):
    expanded_primers = []
    for base in primer:
        if base == 'R':
            expanded_primers.append(['A', 'G'])
        elif base == 'Y':
            expanded_primers.append(['C', 'T'])
        elif base == 'M':
            expanded_primers.append(['A', 'C'])
        else:
            expanded_primers.append([base])
    return expanded_primers

# Define a function to read the input FASTA file
def read_fasta(file_path):
    with open(file_path, "r") as file:
        sequences = {}
        current_header = None
        for line in file:
            line = line.strip()
            if line.startswith(">"):
                current_header = line
                sequences[current_header] = ""
            else:
                sequences[current_header] += line
    return sequences

# Define a function to write to the output FASTA file
def write_fasta(file_path, primers):
    with open(file_path, "w") as file:
        for header, primer_list in primers.items():
            for i, primer in enumerate(primer_list):
                file.write(f"{header}_{i+1}\n{primer}\n")

# Define the argument parser
parser = argparse.ArgumentParser(description="Generate primer combinations from FASTA input")
parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
parser.add_argument("-o", "--output", required=True, help="Output FASTA file")

# Parse the command line arguments
args = parser.parse_args()

# Read the input primer sequences from the FASTA file
input_sequences = read_fasta(args.input)

# Process each sequence and generate combinations
output_primers = {}
for header, sequence in input_sequences.items():
    expanded_bases = expand_ambiguous_bases(sequence)
    primer_combinations = [''.join(p) for p in product(*expanded_bases)]
    output_primers[header] = primer_combinations

# Write the output to the specified FASTA file
write_fasta(args.output, output_primers)

