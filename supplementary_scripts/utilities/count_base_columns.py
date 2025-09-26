#!/usr/bin/env python3
import argparse, sys, gzip, csv

def open_maybe_gzip(path):
    if path == "-" or path is None:
        return sys.stdin
    if path.endswith(".gz"):
        return gzip.open(path, "rt")
    return open(path, "r")

def fasta_iter(handle):
    name, seq = None, []
    for line in handle:
        if not line:
            continue
        if line.startswith(">"):
            if name is not None:
                yield name, "".join(seq)
            name = line[1:].strip()
            seq = []
        else:
            seq.append(line.strip())
    if name is not None:
        yield name, "".join(seq)

def main():
    ap = argparse.ArgumentParser(
        description="Count A,C,G,T and gaps (-) per column in an aligned FASTA."
    )
    ap.add_argument("fasta", help="Aligned FASTA (can be .gz). Use '-' for stdin.")
    ap.add_argument("--out", default="counts.tsv", help="Output TSV path (or '-' for stdout)")
    ap.add_argument("--report-other", action="store_true",
                    help="Also report count of characters other than A,C,G,T,-")
    args = ap.parse_args()

    with open_maybe_gzip(args.fasta) as fh:
        it = fasta_iter(fh)
        try:
            name0, seq0 = next(it)
        except StopIteration:
            sys.exit("No sequences found.")
        s0 = seq0.upper()
        L = len(s0)

        A = [0]*L; C = [0]*L; G = [0]*L; T = [0]*L; GAP = [0]*L
        OTHER = [0]*L if args.report_other else None

        def count_into(s):
            for i, ch in enumerate(s):
                if ch == "A": A[i] += 1
                elif ch == "C": C[i] += 1
                elif ch == "G": G[i] += 1
                elif ch == "T": T[i] += 1
                elif ch == "-": GAP[i] += 1
                else:
                    if OTHER is not None: OTHER[i] += 1

        # count first sequence
        count_into(s0)
        nseq = 1

        # count remaining sequences
        for name, seq in it:
            s = seq.upper()
            if len(s) != L:
                sys.exit(f"Error: sequence '{name}' has length {len(s)} but expected {L}.")
            count_into(s)
            nseq += 1

    # write TSV
    outfh = sys.stdout if args.out == "-" else open(args.out, "w", newline="")
    with outfh:
        w = csv.writer(outfh, delimiter="\t")
        header = ["pos","A","C","G","T","gap"]
        if args.report_other: header.append("other")
        w.writerow(header)
        for i in range(L):
            row = [i+1, A[i], C[i], G[i], T[i], GAP[i]]
            if args.report_other: row.append(OTHER[i])
            w.writerow(row)

    print(f"Wrote {L} columns x {nseq} sequences to {args.out}", file=sys.stderr)

if __name__ == "__main__":
    main()
