import gzip
import argparse
import os

def fastq_to_fasta(input_filename, output_filename):
    # Determine if the file is gzipped
    is_gzipped = input_filename.endswith('.gz')

    # Open the input file accordingly
    open_func = gzip.open if is_gzipped else open
    
    with open_func(input_filename, 'rt') as input_file, open(output_filename, 'w') as output_file:
        while True:
            header = input_file.readline().strip()
            if not header:
                break  # Reached end of file
            
            sequence = input_file.readline().strip()
            _ = input_file.readline()  # Skip the "+" line
            _ = input_file.readline()  # Skip the quality scores line
            
            # Write to output in FASTA format
            output_file.write(f'>{header}\n{sequence}\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert FASTQ to FASTA')
    parser.add_argument('-i', '--input', type=str, required=True, help='Input FASTQ file (.fastq or .fastq.gz)')
    parser.add_argument('-o', '--output', type=str, required=True, help='Output FASTA file')
    args = parser.parse_args()

    input_filename = args.input
    output_filename = args.output
    
    # Check if input file exists
    if not os.path.exists(input_filename):
        print(f"Error: The file '{input_filename}' does not exist.")
        exit(1)

    fastq_to_fasta(input_filename, output_filename)
