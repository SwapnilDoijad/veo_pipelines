#!/usr/bin/env python3
"""
Create a presence/absence (1/0) matrix of genome vs gene.

- Genomes are derived from qseqid by taking the first part (default: up to the first '_' or whitespace).
  Example: H447_contig_1 -> H447
- Required columns (case-insensitive): qseqid, gene
- Output delimiter is inferred from -o extension unless --output-sep is provided.

Usage:
  python presence_absence.py -i INPUT -o OUTPUT [--input-sep SEP] [--output-sep SEP]
  # Force TSV if your -o doesn’t end with .tsv/.tab:
  python presence_absence.py -i input.tsv -o output.matrix --output-sep '\t'

Install deps: pip install pandas
"""

import argparse
import sys
import re
from pathlib import Path
import pandas as pd


def guess_sep_from_ext(path: Path, default=","):
    s = str(path).lower()
    if s.endswith(".tsv") or s.endswith(".tab"):
        return "\t"
    if s.endswith(".csv"):
        return ","
    return default


def main():
    ap = argparse.ArgumentParser(description="Create presence/absence (1/0) matrix of genome (from qseqid) vs gene.")
    ap.add_argument("-i", "--input", required=True, help="Input table (TSV/CSV) with columns qseqid and gene.")
    ap.add_argument("-o", "--output", required=True, help="Output matrix file (.csv, .tsv, .tab, or any name).")
    ap.add_argument("--input-sep", default=None, help="Input delimiter (e.g. '\\t' for TSV). If not set, inferred by -i.")
    ap.add_argument("--output-sep", default=None, help="Output delimiter (e.g. '\\t' for TSV). If not set, inferred by -o.")
    ap.add_argument("--qcol", default="qseqid", help="Genome id column name (default: qseqid). Case-insensitive.")
    ap.add_argument("--gcol", default="gene", help="Gene column name (default: gene). Case-insensitive.")
    ap.add_argument("--qextract", default=r"^([^\s_]+)",
                    help=r"Regex with one capture group to extract genome from qseqid (default: r'^([^\s_]+)')).")
    ap.add_argument("--no-sort", action="store_true", help="Do not sort rows/columns in the output.")
    args = ap.parse_args()

    in_path = Path(args.input)
    out_path = Path(args.output)

    # Delimiters
    in_sep = args.input_sep or guess_sep_from_ext(in_path, default=",")
    out_sep = args.output_sep or guess_sep_from_ext(out_path, default=",")

    # Read input as strings
    try:
        df = pd.read_csv(in_path, sep=in_sep, dtype=str)
    except Exception as e:
        print(f"[ERROR] Failed to read input '{in_path}': {e}", file=sys.stderr)
        sys.exit(1)

    # Resolve columns case-insensitively
    cols_lower = {c.lower(): c for c in df.columns}
    qcol_lc, gcol_lc = args.qcol.lower(), args.gcol.lower()
    if qcol_lc not in cols_lower or gcol_lc not in cols_lower:
        print(
            f"[ERROR] Required columns not found. Available columns: {list(df.columns)}. "
            f"Expected '{args.qcol}' and '{args.gcol}' (case-insensitive).",
            file=sys.stderr,
        )
        sys.exit(2)

    qcol, gcol = cols_lower[qcol_lc], cols_lower[gcol_lc]

    # Clean
    df[qcol] = df[qcol].str.strip()
    df[gcol] = df[gcol].str.strip()
    df = df.dropna(subset=[qcol, gcol])
    df = df[(df[qcol] != "") & (df[gcol] != "")]

    # Extract genome prefix from qseqid
    try:
        pattern = re.compile(args.qextract)
    except re.error as e:
        print(f"[ERROR] Invalid --qextract regex: {e}", file=sys.stderr)
        sys.exit(3)

    qraw = df[qcol].astype(str)

    # First try regex group(1); fallback to first token split by underscore/whitespace
    prefix = qraw.str.extract(pattern, expand=False)
    fallback = qraw.str.split(r"[_\s]", n=1).str[0]
    genome = prefix.fillna(fallback)

    df["_genome"] = genome

    # Keep unique genome–gene pairs
    pairs = df[["_genome", gcol]].drop_duplicates()

    if pairs.empty:
        print("[WARN] No genome–gene pairs found after cleaning; writing empty matrix.", file=sys.stderr)

    # Build matrix
    mat = pd.crosstab(pairs["_genome"], pairs[gcol])
    mat = (mat > 0).astype(int)

    if not args.no_sort:
        mat = mat.sort_index()
        mat = mat.reindex(sorted(mat.columns), axis=1)

    # Write output
    try:
        mat.to_csv(out_path, sep=out_sep, index=True, index_label="genome")
    except Exception as e:
        print(f"[ERROR] Failed to write output '{out_path}': {e}", file=sys.stderr)
        sys.exit(4)

    # Friendly summary (avoid backslashes inside f-strings)
    if out_sep == "\t":
        delim_label = "TAB"
    elif out_sep == ",":
        delim_label = "COMMA"
    else:
        delim_label = f"custom ({repr(out_sep)})"

    msg = (
        f"[OK] Wrote presence/absence matrix: {out_path}\n"
        f"     Genomes (rows): {mat.shape[0]} | Genes (cols): {mat.shape[1]} | Delimiter: {delim_label}"
    )
    print(msg, file=sys.stderr)


if __name__ == "__main__":
    main()
