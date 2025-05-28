import argparse
import gzip
from Bio import SeqIO

def filter_reads_by_length(input_file, seq_length, file_format="fastq"):
    """
    Prints the read ID if its sequence matches the specified length.

    :param input_file: Path to the sequence file (FASTA, FASTQ, etc.)
    :param seq_length: Desired sequence length to filter
    :param file_format: Format of the input file (default is FASTQ)
    """
    # Open file normally or with gzip if it's compressed
    open_func = gzip.open if input_file.endswith(".gz") else open
    
    with open_func(input_file, "rt") as handle:
        for record in SeqIO.parse(handle, file_format):
            if len(record.seq) == seq_length:
                print(record.id)

def main():
    parser = argparse.ArgumentParser(description="Filter sequence reads by length")
    parser.add_argument("-i", "--input", required=True, help="Input sequence file (FASTA/FASTQ, supports .gz)")
    parser.add_argument("-l", "--length", type=int, required=True, help="Length of sequences to filter")
    parser.add_argument("-f", "--format", default="fastq", choices=["fasta", "fastq"], help="File format (default: fastq)")

    args = parser.parse_args()

    filter_reads_by_length(args.input, args.length, args.format)

if __name__ == "__main__":
    main()
