#!/usr/bin/env python3

import argparse
import os

def main():
    parser = argparse.ArgumentParser(description="Calculate total length and overall GC content of a multi-FASTA file")
    parser.add_argument("-i", "--input", required=True, help="Input multi-FASTA file")
    args = parser.parse_args()

    gc_count = 0
    total_bases = 0

    with open(args.input) as f:
        for line in f:
            if line.startswith(">"):
                continue
            seq = line.strip().upper()
            gc_count += seq.count("G") + seq.count("C")
            total_bases += sum(seq.count(b) for b in "ATGC")

    gc_percent = (gc_count / total_bases * 100) if total_bases > 0 else 0

    file_id = os.path.basename(args.input)
    print(f"{file_id}\t{total_bases}\t{gc_percent:.2f}")


if __name__ == "__main__":
    main()
