#!/usr/bin/env python3
"""
Memory-lite ICTV submission builder
----------------------------------

This variant avoids wide pivots and heavy joins and can run with much lower RAM
(<~ a few GB on large inputs). It:
  - Reads only the needed columns from taxonomy TSV
  - Skips the ICTV VMR join (optional, toggle via --use-ictv if really needed)
  - Builds the final table by per-rank left joins (2 columns at a time)
  - Fills missing ranks with "unclassified" and score=1.0
  - Outputs in the official template order with labeled rank headers

Usage:
  python ictv_submission_builder.py \
    --taxonomy-result taxonomyResult.tsv \
    --fasta all59907.fasta \
    --out submission_ictv.csv [--no-labeled-headers] [--delimiter "	"]

Notes:
- Expects Polars >= 1.0.
- taxonomyResult.tsv is assumed to be TSV with NO header.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import List, Set

import polars as pl

# ------------------------------ Config ------------------------------ #
RANKS = [
    "Realm",
    "Subrealm",
    "Kingdom",
    "Subkingdom",
    "Phylum",
    "Subphylum",
    "Class",
    "Subclass",
    "Order",
    "Suborder",
    "Family",
    "Subfamily",
    "Genus",
    "Subgenus",
    "Species",
]

RANK_LABELS = {
    "Realm": "Realm (-viria)",
    "Subrealm": "Subrealm (-vira)",
    "Kingdom": "Kingdom (-virae)",
    "Subkingdom": "Subkingdom (-virites)",
    "Phylum": "Phylum (-viricota)",
    "Subphylum": "Subphylum (-viricotina)",
    "Class": "Class (-viricetes)",
    "Subclass": "Subclass (-viricetidae)",
    "Order": "Order (-virales)",
    "Suborder": "Suborder (-virineae)",
    "Family": "Family (-viridae)",
    "Subfamily": "Subfamily (-virinae)",
    "Genus": "Genus (-virus)",
    "Subgenus": "Subgenus (-virus)",
    "Species": "Species (binomial)",
}

# ------------------------------ Core logic ------------------------------ #

def build_submission(
    taxonomy_tsv: Path,
    fasta_path: Path,
    labeled_headers: bool = True,
) -> pl.DataFrame:
    tax_cols = [
        "qseqid",
        "LCA_ncbi_taxid",
        "rank",
        "taxon_name",
        "protein_fragments",
        "protein_fragments_retained",
        "protein_fragments_assigned",
        "protein_fragments_in_agreement_with_lca",
        "lineage",
    ]

    # Read minimal columns, tolerate ragged lines
    tax = pl.read_csv(
        taxonomy_tsv,
        separator="	",
        has_header=False,
        new_columns=tax_cols,
        ignore_errors=True,
        truncate_ragged_lines=True,
        columns=["qseqid", "rank", "taxon_name", "protein_fragments_in_agreement_with_lca"],
    ).rename(
        {
            "qseqid": "SequenceID",
            "rank": "Rank",
            "taxon_name": "Taxname",
            "protein_fragments_in_agreement_with_lca": "Score",
        }
    )

    # Reduce memory: dictionary-encode strings
    tax = tax.with_columns([
        pl.col("SequenceID"),
        pl.col("Rank").cast(pl.Categorical),
        pl.col("Taxname").cast(pl.Categorical),
        pl.col("Score").cast(pl.Float32),
    ])

    # Base frame of all SequenceIDs
    seq_df = tax.select(pl.col("SequenceID")).unique(maintain_order=True)

    # Iteratively left-join per rank (two columns at a time)
    out = seq_df
    for r in RANKS:
        sub = (
            tax.filter(pl.col("Rank") == r)
               .select([
                   pl.col("SequenceID"),
                   pl.col("Taxname").alias(r),
                   pl.col("Score").alias(f"{r}_score"),
               ])
               .unique(maintain_order=True)
        )
        if not sub.is_empty():
            out = out.join(sub, on="SequenceID", how="left")
        else:
            # Create placeholder cols to keep column order predictable
            out = out.with_columns([
                pl.lit(None, dtype=pl.Utf8).alias(r),
                pl.lit(None, dtype=pl.Float32).alias(f"{r}_score"),
            ])

    # Fill missing ranks/scores
    fill_exprs = []
    for r in RANKS:
        fill_exprs.append(pl.col(r).fill_null("unclassified"))
        fill_exprs.append(pl.col(f"{r}_score").fill_null(1.0))
    out = out.with_columns(fill_exprs)

    # Add missing contigs from FASTA
    contig_names: Set[str] = set()
    with open(fasta_path, "r", encoding="utf-8") as fh:
        for line in fh:
            if line.startswith(">"):
                contig_names.add(line.strip()[1:])

    present_ids = set(out.get_column("SequenceID").to_list())
    missing_ids = sorted(contig_names - present_ids)

    if missing_ids:
        miss = pl.DataFrame({"SequenceID": missing_ids})
        for r in RANKS:
            miss = miss.with_columns([
                pl.lit("unclassified").alias(r),
                pl.lit(1.0).alias(f"{r}_score"),
            ])
        out = pl.concat([out, miss], how="vertical_relaxed")

    # Final column order (labeled or plain)
    if labeled_headers:
        rename_map = {r: RANK_LABELS[r] for r in RANKS}
        out = out.rename(rename_map)
        order = ["SequenceID"]
        for r in RANKS:
            order += [RANK_LABELS[r], f"{r}_score"]
    else:
        order = ["SequenceID"]
        for r in RANKS:
            order += [r, f"{r}_score"]

    return out.select(order)


# ------------------------------ CLI ------------------------------ #

def parse_args(argv: List[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Build an ICTV submission CSV (memory-lite)")
    p.add_argument("--taxonomy-result", required=True, type=Path, help="Path to taxonomyResult.tsv (TSV, no header)")
    p.add_argument("--fasta", required=True, type=Path, help="Path to input FASTA with contig headers")
    p.add_argument("--out", required=True, type=Path, help="Output CSV/TSV path")
    p.add_argument("--no-labeled-headers", dest="labeled", action="store_false", help="Use plain rank headers (no suffix labels)")
    p.add_argument("--delimiter", default="	", help="Output delimiter; default is TAB")
    p.set_defaults(labeled=True)
    return p.parse_args(argv)


def main(argv: List[str]) -> int:
    args = parse_args(argv)

    for path in [args.taxonomy_result, args.fasta]:
        if not path.exists():
            sys.stderr.write(f"ERROR: Missing input file: {path}
")
            return 2

    df = build_submission(
        taxonomy_tsv=args.taxonomy_result,
        fasta_path=args.fasta,
        labeled_headers=args.labeled,
    )

    df.write_csv(args.out, separator=args.delimiter, null_value="")
    print(f"Wrote: {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
