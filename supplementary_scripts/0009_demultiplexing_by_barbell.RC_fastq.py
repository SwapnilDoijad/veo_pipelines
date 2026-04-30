#!/usr/bin/env python3

import sys
import argparse
import gzip

# Reverse-complement translation map
RC_MAP = str.maketrans("ACGTNacgtn", "TGCANtgcan")

def reverse_complement(seq):
    return seq.translate(RC_MAP)[::-1]

def reverse_quality(qual):
    return qual[::-1]

def open_maybe_gzip(path, mode):
    """
    Open a file normally or with gzip depending on extension.
    mode: "rt" or "wt"
    """
    if path.endswith(".gz"):
        return gzip.open(path, mode)
    return open(path, mode)

def process_fastq(in_path, out_path):
    with open_maybe_gzip(in_path, "rt") as infile, \
         open_maybe_gzip(out_path, "wt") as outfile:

        while True:
            header = infile.readline()
            if not header:
                break  # EOF

            seq = infile.readline().rstrip()
            plus = infile.readline()
            qual = infile.readline().rstrip()

            rc_seq = reverse_complement(seq)
            rc_qual = reverse_quality(qual)

            outfile.write(header)
            outfile.write(rc_seq + "\n")
            outfile.write(plus)
            outfile.write(rc_qual + "\n")

def main():
    parser = argparse.ArgumentParser(description="Reverse-complement a FASTQ or FASTQ.GZ file.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ (.fastq, .fq, .gz)")
    parser.add_argument("-o", "--output", required=True, help="Output FASTQ (.fastq, .gz)")

    args = parser.parse_args()

    process_fastq(args.input, args.output)

if __name__ == "__main__":
    main()
