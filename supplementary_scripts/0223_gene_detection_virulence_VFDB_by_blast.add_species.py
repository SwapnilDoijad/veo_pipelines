#!/usr/bin/env python3
import pandas as pd
import argparse

def main():
    parser = argparse.ArgumentParser(description="Merge genome matrix with species table")
    parser.add_argument("-i", "--input_matrix", required=True, help="Input genome matrix TSV (must have column 'genome')")
    parser.add_argument("-s", "--species_table", required=True, help="Species table TSV (must have columns 'ids' and 'species')")
    parser.add_argument("-o", "--output", required=True, help="Output merged TSV file")
    args = parser.parse_args()

    # Load files
    matrix_df = pd.read_csv(args.input_matrix, sep="\t")
    species_df = pd.read_csv(args.species_table, sep="\t")

    # Merge
    merged = pd.merge(species_df, matrix_df, left_on="ids", right_on="genome", how="inner")

    # Drop duplicate genome column
    merged = merged.drop(columns=["genome"])

    # Reorder: species first, then ids, then all features
    merged = merged[["species", "ids"] + [c for c in merged.columns if c not in ["species", "ids"]]]

    # Save
    merged.to_csv(args.output, sep="\t", index=False)

if __name__ == "__main__":
    main()
