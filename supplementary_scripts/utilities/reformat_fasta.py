import argparse

def reformat_fasta(input_file, output_file, line_length=0):
    with open(input_file, 'r') as infile:
        lines = infile.readlines()

    # Initialize variables
    formatted_output = []
    current_sequence = ""  # use a single string for the sequence

    for line in lines:
        if line.startswith(">"):  # Header line
            if current_sequence:
                # Wrap only if a positive line_length was requested, else keep single line
                if line_length and line_length > 0:
                    wrapped = '\n'.join(current_sequence[i:i+line_length]
                                        for i in range(0, len(current_sequence), line_length))
                else:
                    wrapped = current_sequence
                formatted_output.append(wrapped)
                current_sequence = ""
            formatted_output.append(line.strip())  # Add the header
        else:
            # Add sequence lines (removing whitespace and converting to uppercase)
            current_sequence += line.strip().upper()

    # Add the last sequence to the output
    if current_sequence:
        if line_length and line_length > 0:
            wrapped = '\n'.join(current_sequence[i:i+line_length]
                                for i in range(0, len(current_sequence), line_length))
        else:
            wrapped = current_sequence
        formatted_output.append(wrapped)

    # Write the formatted output to the file
    with open(output_file, 'w') as outfile:
        outfile.write('\n'.join(formatted_output) + '\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Reformat FASTA file to a specified line length (0 = single line).")
    
    # Input file argument
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
    
    # Output file argument
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file")
    
    # Line length (0 = single line)
    parser.add_argument("-l", "--line-length", type=int, default=0,
                        help="Maximum number of nucleotides per line. Use 0 for a single-line sequence (default: 0).")
    
    args = parser.parse_args()

    # Run the reformatting
    reformat_fasta(args.input, args.output, args.line_length)
