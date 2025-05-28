#!/usr/bin/env python3

import argparse
from Bio import AlignIO

# Set up argument parser
parser = argparse.ArgumentParser(description="Convert sequence alignment format using Biopython.")
parser.add_argument("-i", "--input", required=True, help="Input alignment file (FASTA format).")
parser.add_argument("-o", "--output", required=True, help="Output alignment file (MAF format).")

args = parser.parse_args()

# Open input and output files
with open(args.input, "r") as input_handle, open(args.output, "w") as output_handle:
    alignments = AlignIO.parse(input_handle, "fasta")
    AlignIO.write(alignments, output_handle, "maf")
