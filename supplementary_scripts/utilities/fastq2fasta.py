import gzip
import argparse

def fastq_to_fasta(input_filename, output_filename):
    with gzip.open(input_filename, 'rt') as input_file, open(output_filename, 'w') as output_file:
        while True:
            header = input_file.readline().strip()
            if not header:
                break  # Reached end of file
            
            sequence = input_file.readline().strip()
            _ = input_file.readline()  # Skip the "+" line
            _ = input_file.readline()  # Skip the quality scores line
            
            output_file.write(f'>{header}\n{sequence}\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert FASTQ to FASTA')
    parser.add_argument('-i', '--input', type=str, required=True, help='Input FASTQ file (.gz)')
    parser.add_argument('-o', '--output', type=str, required=True, help='Output FASTA file')
    args = parser.parse_args()

    input_filename = args.input
    output_filename = args.output
    
    fastq_to_fasta(input_filename, output_filename)
