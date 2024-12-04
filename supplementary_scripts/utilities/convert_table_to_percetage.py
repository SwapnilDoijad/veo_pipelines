import argparse
import pandas as pd

def convert_to_percentages(input_file, output_file):
    # Read the input file into a pandas DataFrame
    df = pd.read_csv(input_file, delimiter='\t')

    # Calculate the sum of values in each column (excluding the 'ids' column)
    sums = df.iloc[:, 1:].sum()

    # Convert values to percentages and round to 2 decimal places
    df.iloc[:, 1:] = (df.iloc[:, 1:].div(sums) * 100).round(2)

    # Save the resulting DataFrame to the output file
    df.to_csv(output_file, sep='\t', index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert values in a TSV file to percentages.")
    parser.add_argument("-i", "--input", help="Input TSV file", required=True)
    parser.add_argument("-o", "--output", help="Output TSV file", required=True)
    args = parser.parse_args()

    convert_to_percentages(args.input, args.output)

