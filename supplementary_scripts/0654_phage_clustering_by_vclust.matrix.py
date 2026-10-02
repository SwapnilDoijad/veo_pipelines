#!/usr/bin/env python3

import argparse
from pathlib import Path
import pandas as pd

def main():
    parser = argparse.ArgumentParser(
        description="Create ANI and distance matrices from vClust ani.tsv"
    )

    parser.add_argument("-i", "--input", required=True, help="vClust ani.tsv")
    parser.add_argument("-o", "--outdir", required=True, help="Output directory")
    parser.add_argument("--ids", default=None, help="Optional vClust ani.ids.tsv file")

    parser.add_argument(
        "--metric",
        default="ani",
        choices=["ani", "gani", "tani"],
        help="Similarity column to use [default: ani]"
    )
    parser.add_argument(
        "--min-cov",
        type=float,
        default=None,
        help="Minimum coverage cutoff, e.g. 0.85"
    )
    parser.add_argument(
        "--min-sim",
        type=float,
        default=None,
        help="Minimum ANI/gANI/tANI cutoff, e.g. 0.95"
    )

    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(args.input, sep="\t")

    required = ["id1", "id2", args.metric]
    if args.min_cov is not None:
        required.append("cov")

    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(
            f"Missing columns: {missing}\n"
            f"Available columns: {list(df.columns)}"
        )

    # Apply optional filters
    original_pairs = len(df)

    if args.min_cov is not None:
        df = df[df["cov"] >= args.min_cov]

    if args.min_sim is not None:
        df = df[df[args.metric] >= args.min_sim]

    print(f"Original pairs: {original_pairs}")
    print(f"Pairs used for matrix: {len(df)}")

    # Genome list
    if args.ids:
        ids_df = pd.read_csv(args.ids, sep="\t", header=None)
        genomes = sorted(ids_df.iloc[:, 0].astype(str).tolist())
        print(f"Genome IDs loaded from --ids: {len(genomes)}")
    else:
        genomes = sorted(set(df["id1"]).union(set(df["id2"])))
        print(f"Genome IDs found in ANI table: {len(genomes)}")

    if len(genomes) == 0:
        raise ValueError("No genomes found.")

    # Create similarity matrix
    sim = df.pivot_table(
        index="id1",
        columns="id2",
        values=args.metric,
        aggfunc="max"
    )

    # Make symmetric
    sim = sim.combine_first(sim.T)

    # Reindex using genome list
    sim = sim.reindex(index=genomes, columns=genomes)

    # Diagonal = 1
    for g in genomes:
        sim.loc[g, g] = 1.0

    # Missing comparisons = 0 similarity
    sim = sim.fillna(0)

    # Distance = 1 - similarity
    dist = 1 - sim

    # Round to 3 decimals
    sim = sim.round(3)
    dist = dist.round(3)

    suffix = args.metric

    if args.min_sim is not None:
        suffix += f"_minsim{args.min_sim}"

    if args.min_cov is not None:
        suffix += f"_mincov{args.min_cov}"

    sim_out = outdir / f"{suffix}_ANI_matrix.tsv"
    dist_out = outdir / f"{suffix}_distance_matrix.tsv"

    sim.to_csv(sim_out, sep="\t", float_format="%.3f")
    dist.to_csv(dist_out, sep="\t", float_format="%.3f")

    print(f"{args.metric.upper()} matrix written to: {sim_out}")
    print(f"Distance matrix written to: {dist_out}")


if __name__ == "__main__":
    main()