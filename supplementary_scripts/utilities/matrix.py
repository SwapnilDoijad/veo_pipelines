import pandas as pd
import argparse

def create_matrix(input_file, output_file, column_index):
    # Read the input file
    df = pd.read_csv(input_file, sep="\t", header=None)

    # Convert 1-based index to 0-based index
    column_index -= 1  # Adjust for Python indexing

    # Check if the specified column index is valid
    if column_index < 0 or column_index >= len(df.columns):
        raise ValueError(f"Column index {column_index + 1} is out of range. File has {len(df.columns)} columns.")

    # Select only relevant columns (Row, Column, and the chosen Value column)
    df_selected = df.iloc[:, [0, 1, column_index]]

    # Rename the columns for clarity
    df_selected.columns = ["Row", "Column", "Value"]

    # Convert values to numeric and round to two decimal places
    df_selected["Value"] = pd.to_numeric(df_selected["Value"], errors="coerce").round(2)

    # Pivot the table to form a matrix
    matrix = df_selected.pivot(index="Row", columns="Column", values="Value")

    # Save the output matrix to a file
    matrix.to_csv(output_file, sep="\t", float_format="%.2f")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a matrix from input data with a specified value column (rounded to 2 decimal places)")
    parser.add_argument("-i", "--input", required=True, help="Input file path")
    parser.add_argument("-o", "--output", required=True, help="Output file path")
    parser.add_argument("-c", "--column", type=int, required=True, help="Column index (1-based) to use as values")

    args = parser.parse_args()

    create_matrix(args.input, args.output, args.column)



# Edit (input.txt with more columns)
# A	A	AFGDT	100	Extra1	Extra2
# A	B	AFGDT	90	Extra1	Extra2
# A	C	AFGDT	90	Extra1	Extra2
# B	A	AFGDT	90	Extra1	Extra2
# B	B	AFGDT	100	Extra1	Extra2
# B	C	AFGDT	90	Extra1	Extra2
# C	A	AFGDT	90	Extra1	Extra2
# C	B	AFGDT	90	Extra1	Extra2
# C	C	AFGDT	100	Extra1	Extra2

# Output (output.txt):
# Row	A	B	C
# A	100	90	90
# B	90	100	90
# C	90	90	100