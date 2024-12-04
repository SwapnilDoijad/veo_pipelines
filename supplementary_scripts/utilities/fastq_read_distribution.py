import argparse
import gzip
import os
from collections import Counter

def get_read_length(sequence):
    return len(sequence)

def main(input_file, output_file):
    try:
        if input_file.endswith('.gz'):
            infile = gzip.open(input_file, 'rt')
        else:
            infile = open(input_file, 'rt')

        with infile, open(output_file, 'wt') as outfile:
            read_lengths = []

            while True:
                header = infile.readline()
                if not header:  # if the line is empty, end of file is reached
                    break
                sequence = infile.readline().strip()
                plus = infile.readline()
                quality = infile.readline()

                read_lengths.append(get_read_length(sequence))

            # Count the occurrences of each read length
            length_counts = Counter(read_lengths)

            # Sort the lengths
            sorted_lengths = sorted(length_counts.items())

            # Write the lengths and their counts to the output file
            for length, count in sorted_lengths:
                outfile.write(f"{length}\t{count}\n")

        print(f"Read lengths and their counts written to {output_file}")
    except FileNotFoundError:
        print("File not found:", input_file)
    except Exception as e:
        print("An error occurred:", str(e))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract read lengths from a FASTQ file.")
    parser.add_argument('-i', '--input', required=True, help='Input FASTQ file path')
    parser.add_argument('-o', '--output', required=True, help='Output file path')

    args = parser.parse_args()

    main(args.input, args.output)
