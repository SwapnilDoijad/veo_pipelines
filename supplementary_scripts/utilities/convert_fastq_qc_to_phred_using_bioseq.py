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
from Bio import SeqIO

def convert_phred_scores(input_fastq, output_fastq):
    with open(input_fastq, "r") as infile, open(output_fastq, "w") as outfile:
        for record in SeqIO.parse(infile, "fastq"):
            # PHRED scores are already in numeric format in record.letter_annotations["phred_quality"]
            phred_scores = record.letter_annotations["phred_quality"]
            # Update the record with converted scores
            record.letter_annotations["phred_quality"] = phred_scores
            # Write the updated record to the output file
            SeqIO.write(record, outfile, "fastq")

def main():
    parser = argparse.ArgumentParser(description="Convert PHRED scores from ASCII to numeric in a FASTQ file.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ file")
    parser.add_argument("-o", "--output", required=True, help="Output FASTQ file with converted PHRED scores")

    args = parser.parse_args()
    convert_phred_scores(args.input, args.output)

if __name__ == "__main__":
    main()
