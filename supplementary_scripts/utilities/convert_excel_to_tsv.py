import pandas as pd
import argparse

# Set up argument parser
parser = argparse.ArgumentParser(description="Convert Excel file to TSV format.")
parser.add_argument("-i", "--input", required=True, help="Path to the input Excel file.")
parser.add_argument("-o", "--output", required=True, help="Path to the output TSV file.")

# Parse arguments
args = parser.parse_args()
excel_file = args.input
tsv_file = args.output

# Load the Excel file
df = pd.read_excel(excel_file, engine='openpyxl')

# Save as TSV
df.to_csv(tsv_file, sep='\t', index=False)

print(f"Converted {excel_file} to {tsv_file}")