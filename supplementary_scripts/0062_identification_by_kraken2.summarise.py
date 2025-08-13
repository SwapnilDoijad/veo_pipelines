#!/usr/bin/env python3
import csv
import argparse
from collections import namedtuple, Counter
import sys

ReportRow = namedtuple("ReportRow", "pct clade direct rank taxid name")

# Common Kraken/NCBI rank codes
RANK_LABELS = {
    "U": "unclassified",
    "R": "root",
    "D": "domain/superkingdom",
    "K": "kingdom",
    "P": "phylum",
    "C": "class",
    "O": "order",
    "F": "family",
    "G": "genus",
    "S": "species",
    # Kraken may also emit intermediate codes like R1, G1, etc.
}

def parse_report(path):
    rows = []
    with open(path, newline="") as fh:
        rd = csv.reader(fh, delimiter="\t")
        for r in rd:
            if not r:
                continue
            r += [""] * (6 - len(r))          # ensure at least 6 fields
            name = " ".join(r[5:]).lstrip()   # join name columns, strip leading spaces
            try:
                rows.append(ReportRow(float(r[0]), int(r[1]), int(r[2]), r[3], r[4], name))
            except ValueError:
                continue
    return rows

def summarize(rows, rank="S", top_n=10, drop_unclassified=True):
    xs = [r for r in rows if r.rank == rank]
    if drop_unclassified:
        xs = [r for r in xs if not r.name.lower().startswith("unclassified ")]
    xs.sort(key=lambda r: r.pct, reverse=True)
    top = xs[:top_n]
    other = sum(r.pct for r in xs[top_n:])
    return top, other

def list_ranks(rows):
    cnt = Counter(r.rank for r in rows)
    lines = []
    for rk, n in sorted(cnt.items(), key=lambda x: (x[0], -x[1])):
        label = RANK_LABELS.get(rk, "unranked/intermediate")
        lines.append(f"{rk:<3} {label:<25}  {n} rows")
    return "\n".join(lines)

def main():
    parser = argparse.ArgumentParser(description="Summarize a Kraken2 report by rank.")
    parser.add_argument("-i", "--input", required=True, help="Input Kraken2 report file")
    parser.add_argument("-o", "--output", required=True, help="Output summary file (TSV by default)")
    parser.add_argument(
        "-r", "--rank", default="S",
        help=("Rank code to summarize (default: S for species). "
              "Common: U (unclassified), R (root), D (domain), K (kingdom), "
              "P (phylum), C (class), O (order), F (family), G (genus), S (species). "
              "Kraken may also emit intermediate codes like R1, G1, etc.")
    )
    parser.add_argument("-n", "--topN", type=int, default=10, help="Number of top taxa to keep (default: 10)")
    parser.add_argument("--keep-unclassified", action="store_true", help="Include 'unclassified ...' taxa")
    parser.add_argument("--list-ranks", action="store_true",
                        help="Print all rank codes present in the input (with counts) and exit")
    parser.add_argument("--csv", action="store_true", help="Write output as comma-separated (override default TSV)")

    args = parser.parse_args()

    rows = parse_report(args.input)

    if args.list_ranks:
        print(list_ranks(rows))
        sys.exit(0)

    top, other = summarize(
        rows, rank=args.rank, top_n=args.topN, drop_unclassified=not args.keep_unclassified
    )

    delimiter = "," if args.csv else "\t"
    with open(args.output, "w", newline="") as fh:
        w = csv.writer(fh, delimiter=delimiter)
        w.writerow(["rank", "name", "clade_percent", "clade_reads", "taxid"])
        for r in top:
            w.writerow([r.rank, r.name, r.pct, r.clade, r.taxid])
        if other > 0:
            w.writerow([args.rank, "Other", other, "", ""])

if __name__ == "__main__":
    main()
