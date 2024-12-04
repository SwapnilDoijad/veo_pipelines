import argparse

def reformat_fasta(input_file, output_file, line_length=60):
    with open(input_file, 'r') as infile:
        # Read the file and split into header and sequence
        lines = infile.readlines()
        header = lines[0].strip()
        sequence = ''.join([line.strip() for line in lines[1:]])

    # Convert sequence to uppercase
    sequence = sequence.upper()

    # Break sequence into chunks of `line_length`
    formatted_sequence = '\n'.join([sequence[i:i+line_length] for i in range(0, len(sequence), line_length)])

    # Write the output to the file
    with open(output_file, 'w') as outfile:
        outfile.write(f"{header}\n{formatted_sequence}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Reformat FASTA file to a specified line length.")
    
    # Input file argument
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
    
    # Output file argument
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file")
    
    args = parser.parse_args()

    # Run the reformatting
    reformat_fasta(args.input, args.output)
