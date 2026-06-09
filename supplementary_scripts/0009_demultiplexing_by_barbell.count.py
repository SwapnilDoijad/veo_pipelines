#!/usr/bin/env python3
"""Count matches per primer efficiently by streaming annotations.tsv.

Usage examples:
    python scripts/count_primers.py -p primers.txt -i annotations.tsv
    python scripts/count_primers.py -p primers.txt -i ann1.tsv ann2.tsv -o counts.tsv
"""
import argparse
import csv
import sys


def parse_args():
    p = argparse.ArgumentParser(description="Count rows per primer matching conditions")
    p.add_argument("-p", "--primers", required=True,
                   help="file with one primer id per line")
    p.add_argument("-i", "--input", required=True, nargs='+',
                   help="annotations.tsv files (tab-delimited). Accepts one or more files")
    p.add_argument("-o", "--output", help="output file (default stdout)")
    p.add_argument("-f", "--flank-cost", dest="flank_cost", type=float, default=10,
                   help="threshold for field 11 (default: 10)")
    p.add_argument("-b", "--barcode-cost", dest="barcode_cost", type=float, default=2,
                   help="threshold for field 12 (default: 2)")
    return p.parse_args()


def main():
    args = parse_args()

    # Read primers (keep order)
    with open(args.primers, "r") as fh:
        primers = [line.strip() for line in fh if line.strip()]
    primers_set = set(primers)
    counts = {p: 0 for p in primers}

    # Stream one or more annotations.tsv files — check columns 11,12,13 (1-based)
    for annpath in args.input:
        with open(annpath, newline="") as ann:
            reader = csv.reader(ann, delimiter="\t")
            for fields in reader:
                if len(fields) < 13:
                    continue
                pid = fields[12]
                if pid not in primers_set:
                    continue
                # fields[10] == $11, fields[11] == $12
                try:
                    v11 = float(fields[10])
                    v12 = float(fields[11])
                except ValueError:
                    continue
                if v11 <= args.flank_cost and v12 <= args.barcode_cost:
                    counts[pid] = counts.get(pid, 0) + 1

    out = open(args.output, "w") if args.output else sys.stdout
    for p in primers:
        out.write(f"{p}\t{counts.get(p,0)}\n")
    if args.output:
        out.close()


if __name__ == "__main__":
    main()
