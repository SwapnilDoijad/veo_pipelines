import argparse

def check_consistency(input_file, output_file):
    with open(input_file, 'r') as file:
        lines = file.readlines()

    # Get the number of columns in the first row
    num_columns = len(lines[0].strip().split('\t'))
    num_rows = len(lines)

    consistent = True
    output_lines = []
    for i, line in enumerate(lines):
        columns = line.strip().split('\t')
        if len(columns) != num_columns:
            output_lines.append(f"Inconsistent number of columns at row {i+1}: {len(columns)} columns found, expected {num_columns} columns.\n")
            consistent = False

    if consistent:
        output_lines.append("All rows have a consistent number of columns.\n")

    # Check the total number of rows
    if consistent:
        output_lines.append(f"Number of rows: {num_rows}\n")
        output_lines.append(f"Number of columns: {num_columns}\n")

    with open(output_file, 'w') as out_file:
        out_file.writelines(output_lines)

    print(f"Number of rows: {num_rows}")
    print(f"Number of columns: {num_columns}")

    if consistent:
        print("All rows have a consistent number of columns.")
    else:
        print("Inconsistencies found. Check the output file for details.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Check consistency of column numbers in a tab-separated table.')
    parser.add_argument('-i', '--input', required=True, help='Input tab-separated file')
    parser.add_argument('-o', '--output', required=True, help='Output file for consistency check results')

    args = parser.parse_args()

    check_consistency(args.input, args.output)
