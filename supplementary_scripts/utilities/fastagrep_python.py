## need to sallo --cpus-per-task=40
## for biopython, need to "source /home/groups/VEO/tools/python/biopython/bin/activate"
## python script_name.py -i input_file.fasta -o output_folder -H header_file.txt

import argparse
from Bio import SeqIO
from Bio import pairwise2
from multiprocessing import Pool
from datetime import datetime
import os

def find_matching_headers(query_header, target_headers, similarity_threshold=0.9):
    matching_headers = []

    for target_header in target_headers:
        alignments = pairwise2.align.localms(query_header, target_header, 2, -1, -0.5, -0.1, one_alignment_only=True)

        if alignments:
            best_alignment = alignments[0]
            alignment_length = max(len(best_alignment.seqA), len(best_alignment.seqB))
            similarity = best_alignment.score / alignment_length

            if similarity >= similarity_threshold:
                matching_headers.append(target_header)

    return matching_headers

def extract_sequence(header, multi_fasta_file):
    matching_headers = find_matching_headers(header, all_headers)

    if matching_headers:
        sequences = {}
        with open(multi_fasta_file, 'r') as f:
            for record in SeqIO.parse(f, "fasta"):
                if record.id in matching_headers:
                    sequences[record.id] = str(record.seq)

        return sequences

    else:
        print("No matching header found")
        return {}

def write_fasta_batch(header_sequences, output_folder):
    os.makedirs(output_folder, exist_ok=True)

    for header, sequence in header_sequences.items():
        output_file = os.path.join(output_folder, f'{header}.fasta')
        with open(output_file, 'w') as f:
            f.write(f'>{header}\n{sequence}')

def main(args):
    header = args.header
    multi_fasta_file = args.input
    output_folder = args.output

    global all_headers
    all_headers = [header]

    with Pool(processes=40) as pool:
        results = pool.starmap(extract_sequence, [(header, multi_fasta_file)])

    result_sequences = {header: sequence for batch_result in results for header, sequence in batch_result.items()}

    if not any(result_sequences.values()):
        print("No sequences extracted.")
    else:
        with Pool(processes=40) as pool:
            pool.starmap(write_fasta_batch, [(result_sequences, output_folder)])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract sequences from a multi-FASTA file based on a list of headers.')
    parser.add_argument('-i', '--input', type=str, required=True, help='Input multi-FASTA file')
    parser.add_argument('-o', '--output', type=str, required=True, help='Output folder for extracted sequences')
    parser.add_argument('-H', '--header', type=str, required=True, help='Header to search for')
    args = parser.parse_args()
    
    main(args)
