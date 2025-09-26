import argparse
import gzip
from Bio import SeqIO

def extract_reads(input_file, output_file, id_list_file):
    # Read the list of read IDs
    with open(id_list_file, 'r') as f:
        id_list = set(line.strip() for line in f)

    # Parse the input FASTQ file and filter reads based on the provided IDs
    with get_input_handle(input_file) as in_handle:
        with gzip.open(output_file, 'wt') as out_handle:
            for record in SeqIO.parse(in_handle, 'fastq'):
                # Extract the unique ID part from the record ID
                record_id = record.id.split()[0]  # Take only the part before the first space
                if record_id in id_list:
                    SeqIO.write(record, out_handle, 'fastq')

def get_input_handle(input_file):
    # Check if the input file is compressed (ends with ".gz")
    if input_file.endswith('.gz'):
        return gzip.open(input_file, 'rt')
    else:
        return open(input_file, 'r')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extract reads from a FASTQ file based on a list of read IDs')
    parser.add_argument('-i', '--input', help='Input FASTQ file', required=True)
    parser.add_argument('-o', '--output', help='Output FASTQ.gz file', required=True)
    parser.add_argument('-l', '--id_list', help='File containing list of read IDs', required=True)
    args = parser.parse_args()

    # Ensure the output file ends with '.gz'
    if not args.output.endswith('.gz'):
        args.output += '.gz'

    # Call the extract_reads function with the provided arguments
    extract_reads(args.input, args.output, args.id_list)
