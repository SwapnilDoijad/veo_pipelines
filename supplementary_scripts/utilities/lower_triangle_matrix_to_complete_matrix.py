import argparse
import numpy as np
import pandas as pd

def build_symmetric_matrix(file_path):
    # Read input file
    with open(file_path, 'r') as f:
        lines = [line.strip().split('\t') for line in f if line.strip()]
    
    # Extract identifiers
    ids = [line[0] for line in lines]
    n = len(ids)

    # Initialize empty matrix
    matrix = np.zeros((n, n))

    # Fill in the lower triangle
    for i, line in enumerate(lines):
        for j, val in enumerate(line[1:]):
            matrix[i][j] = float(val)

    # Fill in the upper triangle by symmetry
    i_lower = np.tril_indices(n, -1)
    matrix[i_lower[1], i_lower[0]] = matrix[i_lower]

    # Create DataFrame
    df = pd.DataFrame(matrix, index=ids, columns=ids)
    return df

def main():
    parser = argparse.ArgumentParser(description="Convert lower triangular matrix into full symmetric matrix")
    parser.add_argument('-i', '--input', required=True, help='Input file with lower triangle matrix data')
    parser.add_argument('-o', '--output', required=True, help='Output file to save the full matrix (TSV format)')
    args = parser.parse_args()

    df = build_symmetric_matrix(args.input)
    
    # Save to TSV (tab-separated file)
    df.to_csv(args.output, sep='\t')
    print(f"Matrix saved to {args.output} in TSV format.")

if __name__ == '__main__':
    main()
