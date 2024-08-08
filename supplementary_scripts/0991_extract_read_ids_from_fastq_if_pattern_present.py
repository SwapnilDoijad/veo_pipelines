import argparse

def find_sequence_in_fastq(sequence, fastq_file, output_file):
    with open(fastq_file, 'r') as f:
        lines = f.readlines()
        num_lines = len(lines)

        with open(output_file, 'w') as out:
            for i in range(0, num_lines, 4):  # Read four lines at a time (header, sequence, "+", quality)
                header = lines[i].strip()
                seq = lines[i+1].strip()

                if sequence in seq:
                    out.write(header + '\n')

# Command-line arguments parsing
parser = argparse.ArgumentParser(description='Find FASTQ headers for a given sequence.')
parser.add_argument('-i', '--input', required=True, help='Input FASTQ file')
parser.add_argument('-s', '--sequence', required=True, help='Sequence to find')
parser.add_argument('-o', '--output', required=True, help='Output file for headers')
args = parser.parse_args()

# Call the function with the provided arguments
find_sequence_in_fastq(args.sequence, args.input, args.output)
