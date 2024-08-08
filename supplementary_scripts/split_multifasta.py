## python3 script.py -i input_multifasta.fasta -o output_fasta_files -c 4
## 20240302: DID NOT worked with multifasta file with 25M fasta sequences, memory error

import os
import argparse
from multiprocessing import Pool

def split_fasta_chunk(chunk):
    for args in chunk:
        split_fasta(args)

def parse_multifasta_chunked(multifasta_path, chunk_size):
    entries = []
    with open(multifasta_path, 'r') as multifasta_file:
        header = None
        sequence = ""
        for line in multifasta_file:
            if line.startswith('>'):
                if header is not None:
                    entries.append((header, sequence))
                header = line[1:].strip()
                sequence = ""
            else:
                sequence += line.strip()
        if header is not None:
            entries.append((header, sequence))
    
    return [entries[i:i+chunk_size] for i in range(0, len(entries), chunk_size)]

def main():
    parser = argparse.ArgumentParser(description='Split multifasta file into individual fasta files.')
    parser.add_argument('-i', '--input', required=True, help='Input multifasta file path')
    parser.add_argument('-o', '--output', required=True, help='Output directory for individual fasta files')
    parser.add_argument('-c', '--cpu', type=int, default=os.cpu_count(), help='Number of CPU cores to use (default: all available cores)')
    parser.add_argument('--chunk-size', type=int, default=100, help='Number of entries to process in each chunk')
    args = parser.parse_args()

    if not os.path.exists(args.output):
        os.makedirs(args.output)

    chunks = parse_multifasta_chunked(args.input, args.chunk_size)
    pool_args = [(header, sequence, args.output) for chunk in chunks for header, sequence in chunk]

    with Pool(processes=args.cpu) as pool:
        pool.map(split_fasta_chunk, chunks)

if __name__ == "__main__":
    main()
