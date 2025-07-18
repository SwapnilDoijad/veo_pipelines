import argparse
import pandas as pd

def transform_matrix(input_file, output_file):
    # Read the TSV file with row IDs as index, treat everything as string first
    df = pd.read_csv(input_file, sep='\t', index_col=0, dtype=str)

    # Convert the internal values to float, keeping the index and column labels intact
    df_numeric = df.apply(pd.to_numeric, errors='coerce')

    # Apply the transformation and round to 3 decimal places
    transformed = ((1 - df_numeric) * 100).round(3)

    # Restore original row and column labels
    transformed.index = df.index
    transformed.columns = df.columns

    # Save the output as TSV
    transformed.to_csv(output_file, sep='\t')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Transform a matrix with (1 - value) * 100, rounded to 3 decimals.")
    parser.add_argument("-i", "--input", required=True, help="Path to input TSV file")
    parser.add_argument("-o", "--output", required=True, help="Path to output TSV file")

    args = parser.parse_args()
    transform_matrix(args.input, args.output)
