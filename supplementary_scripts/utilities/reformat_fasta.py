import argparse

def reformat_fasta(input_file, output_file, line_length=60):
    with open(input_file, 'r') as infile:
        lines = infile.readlines()

    # Initialize variables
    formatted_output = []
    current_sequence = []

    for line in lines:
        if line.startswith(">"):  # Header line
            if current_sequence:
                # Write the previous sequence to the output
                formatted_output.append('\n'.join([''.join(current_sequence[i:i+line_length]) 
                                                   for i in range(0, len(current_sequence), line_length)]))
                current_sequence = []
            formatted_output.append(line.strip())  # Add the header
        else:
            # Add sequence lines (removing whitespace and converting to uppercase)
            current_sequence.append(line.strip().upper())

    # Add the last sequence to the output
    if current_sequence:
        formatted_output.append('\n'.join([''.join(current_sequence[i:i+line_length]) 
                                           for i in range(0, len(current_sequence), line_length)]))

    # Write the formatted output to the file
    with open(output_file, 'w') as outfile:
        outfile.write('\n'.join(formatted_output) + '\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Reformat FASTA file to a specified line length.")
    
    # Input file argument
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
    
    # Output file argument
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file")
    
    args = parser.parse_args()

    # Run the reformatting
    reformat_fasta(args.input, args.output)
