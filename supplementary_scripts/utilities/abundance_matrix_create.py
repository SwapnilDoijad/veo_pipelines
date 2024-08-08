import argparse
import pandas as pd
import os

def merge_data(filepaths):
    dfs = []
    for filepath in filepaths:
        filename = os.path.basename(filepath).replace(".contigs_with_coverage.tsv", "")
        df = pd.read_csv(filepath, sep='\t', header=None, index_col=0, names=['rank', filename])
        dfs.append(df)

    # Ensure all indices are unique
    for i, df in enumerate(dfs):
        dfs[i] = df[~df.index.duplicated()]

    # Concatenate dataframes
    merged_data = pd.concat(dfs, axis=1, sort=False)

    # Fill missing values with 0
    merged_data.fillna(0, inplace=True)

    return merged_data

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Merge data from multiple files.')
    parser.add_argument('-i', '--input', type=str, help='Input file containing filepaths', required=True)
    parser.add_argument('-o', '--output', type=str, help='Output file', required=True)
    args = parser.parse_args()

    # Read filepaths from input file
    with open(args.input, "r") as f:
        filepaths = [line.strip() for line in f.readlines()]

    # Merge data
    merged_data = merge_data(filepaths)

    # Add "matrix" to first row and first column
    merged_data.index.name = "rank"
    merged_data.columns.name = "matrix"

    # Write merged dataframe to output file
    merged_data.to_csv(args.output, sep='\t')

if __name__ == "__main__":
    main()
