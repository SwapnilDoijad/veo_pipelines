import argparse
from Bio import SeqIO

def filter_fasta_by_length(input_fasta, output_fasta, min_length):
    """
    Filters sequences in a multi-FASTA file by minimum length and writes them to a new file.

    :param input_fasta: Path to the input multi-FASTA file.
    :param output_fasta: Path to the output FASTA file where filtered sequences will be written.
    :param min_length: Minimum length of sequences to retain.
    """
    # Open input and output files
    with open(input_fasta, "r") as infile, open(output_fasta, "w") as outfile:
        # Parse the input FASTA file
        for record in SeqIO.parse(infile, "fasta"):
            # Check if the sequence length is greater than or equal to min_length
            if len(record.seq) >= min_length:
                # Write the record to the output file
                SeqIO.write(record, outfile, "fasta")
    print(f"Sequences longer than {min_length} bases have been written to {output_fasta}")

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Filter FASTA sequences by length")
    
    # Add arguments for input, output, and minimum length
    parser.add_argument("-i", "--input", required=True, help="Input multi-FASTA file")
    parser.add_argument("-o", "--output", required=True, help="Output filtered FASTA file")
    parser.add_argument("-l", "--length", type=int, required=True, help="Minimum sequence length to retain")
    
    # Parse the arguments
    args = parser.parse_args()
    
    # Call the filtering function with parsed arguments
    filter_fasta_by_length(args.input, args.output, args.length)

if __name__ == "__main__":
    main()
