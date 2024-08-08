## salloc --cpus-per-task=80 --mem=200G
## python script.py -i input.fasta -f list.txt -o output_folder

import os
import argparse
from multiprocessing import Pool

def extract_sequence(header, sequence, output_directory):
    output_file_path = os.path.join(output_directory, f'{header}.fasta')
    with open(output_file_path, 'w') as output_f:
        output_f.write(f'>{header}\n{sequence}\n')

def extract_sequences_batch(args, batch_size=100):
    # Read headers from the provided file
    with open(args.list_file, 'r') as headers_f:
        headers_to_extract = [line.strip() for line in headers_f]

    # Read sequences from the FASTA file
    sequences = {}
    current_header = None
    current_sequence = ""
    with open(args.input_fasta, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                if current_header is not None:
                    sequences[current_header] = current_sequence
                current_header = line[1:]
                current_sequence = ""
            else:
                current_sequence += line
        # Add the last sequence
        if current_header is not None:
            sequences[current_header] = current_sequence

    # Create output directory if it does not exist
    os.makedirs(args.output_folder, exist_ok=True)

    # Process sequences in batches
    for i in range(0, len(headers_to_extract), batch_size):
        batch_headers = headers_to_extract[i:i + batch_size]
        batch_sequences = {header: sequences[header] for header in batch_headers if header in sequences}

        # Use multiprocessing to write sequences to files in parallel for each batch
        with Pool(args.num_processes) as pool:
            pool.starmap(extract_sequence, [(header, sequence, args.output_folder) for header, sequence in batch_sequences.items()])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract DNA sequences based on headers from a FASTA file.")
    parser.add_argument('-i', '--input_fasta', required=True, help='Input FASTA file path')
    parser.add_argument('-f', '--list_file', required=True, help='File containing the list of headers')
    parser.add_argument('-o', '--output_folder', required=True, help='Output folder for extracted sequences')
    parser.add_argument('-p', '--num_processes', type=int, default=1, help='Number of processes for multiprocessing')
    parser.add_argument('-b', '--batch_size', type=int, default=100, help='Batch size for processing sequences')

    args = parser.parse_args()
    extract_sequences_batch(args, batch_size=args.batch_size)
