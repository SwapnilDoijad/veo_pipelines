import argparse
from Bio import SeqIO

# Create an argument parser
parser = argparse.ArgumentParser(description="Cut and write the first 150 base pairs from a multi-FASTA file to a single output file")

# Define the input and output file arguments
parser.add_argument("-i", "--input_fasta", required=True, help="Input multi-FASTA file")
parser.add_argument("-o", "--output_file", required=True, help="Output file")

# Parse the command-line arguments
args = parser.parse_args()

# Create an empty string to store the extracted sequences
extracted_sequences = ""

# Parse the input multi-FASTA file
for record in SeqIO.parse(args.input_fasta, "fasta"):
    # Extract the first 150 base pairs
    first_150_bp = str(record.seq[:150])
    
    # Append the extracted sequence to the result
    extracted_sequences += f">{record.id}\n{first_150_bp}\n"

# Write all extracted sequences to the output file
with open(args.output_file, "w") as outfile:
    outfile.write(extracted_sequences)

