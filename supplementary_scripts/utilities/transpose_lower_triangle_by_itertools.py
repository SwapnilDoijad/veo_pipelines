import itertools
import argparse

def transpose_file(input_file, output_file):
    # Read the file and process it line by line
    with open(input_file, 'r') as infile:
        # Generator that yields rows split into columns
        rows = (line.strip().split('\t') for line in infile)
        
        # Find the maximum number of columns in all rows
        max_cols = max(len(row) for row in rows)
        
        # Reset the generator for the next iteration
        infile.seek(0)
        rows = (line.strip().split('\t') for line in infile)
        
        # Pad rows to ensure equal length
        padded_rows = (row + [''] * (max_cols - len(row)) for row in rows)
        
        # Transpose the padded rows
        transposed = itertools.zip_longest(*padded_rows, fillvalue='')

    # Write the transposed data to the output file
    with open(output_file, 'w') as outfile:
        for row in transposed:
            outfile.write("\t".join(row).rstrip() + "\n")

if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Transpose a tab-delimited file.")
    parser.add_argument("-i", "--input", required=True, help="Path to the input file")
    parser.add_argument("-o", "--output", required=True, help="Path to the output file")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Call the transpose function
    transpose_file(args.input, args.output)

## 2024-12-02 11:39:40 good for upto 500,000 rows (as suugested for )