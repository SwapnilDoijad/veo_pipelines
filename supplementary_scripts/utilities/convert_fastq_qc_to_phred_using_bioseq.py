# import argparse
# from Bio import SeqIO

# def convert_phred_scores(input_fastq, output_fastq):
#     with open(input_fastq, "r") as infile, open(output_fastq, "w") as outfile:
#         for record in SeqIO.parse(infile, "fastq"):
#             # Convert PHRED scores from ASCII to numeric
#             phred_scores = [ord(char) - 33 for char in record.letter_annotations["phred_quality"]]
#             # Update the record with converted scores
#             record.letter_annotations["phred_quality"] = phred_scores
#             # Write the updated record to the output file
#             SeqIO.write(record, outfile, "fastq")

# def main():
#     parser = argparse.ArgumentParser(description="Convert PHRED scores from ASCII to numeric in a FASTQ file.")
#     parser.add_argument("-i", "--input", required=True, help="Input FASTQ file")
#     parser.add_argument("-o", "--output", required=True, help="Output FASTQ file with converted PHRED scores")

#     args = parser.parse_args()
#     convert_phred_scores(args.input, args.output)

# if __name__ == "__main__":
#     main()

import argparse
import gzip
from Bio import SeqIO

def open_file(filename, mode="rt"):
    """Open a file normally or as a gzip file if it has a .gz extension."""
    if filename.endswith(".gz"):
        return gzip.open(filename, mode)
    else:
        return open(filename, mode)

def convert_phred_scores(input_fastq, output_fastq):
    with open_file(input_fastq, "rt") as infile, open_file(output_fastq, "wt") as outfile:
        for record in SeqIO.parse(infile, "fastq"):
            phred_scores = record.letter_annotations["phred_quality"]
            record.letter_annotations["phred_quality"] = phred_scores  # No actual conversion is needed
            SeqIO.write(record, outfile, "fastq")

def main():
    parser = argparse.ArgumentParser(description="Convert PHRED scores from ASCII to numeric in a FASTQ file.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ file (can be .gz)")
    parser.add_argument("-o", "--output", required=True, help="Output FASTQ file (can be .gz)")

    args = parser.parse_args()
    convert_phred_scores(args.input, args.output)

if __name__ == "__main__":
    main()
