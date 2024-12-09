import pandas as pd
import argparse

def split_snps(row, metadata_columns):
    chrom, pos, ref, alt = row[0], row[1], row[3], row[4]
    metadata = row[5:]
    simple_rows = []

    # Find the minimum length between REF and ALT
    min_len = min(len(ref), len(alt))
    
    # Process substitution for overlapping bases
    for i in range(min_len):
        if ref[i] == alt[i]:
            continue  # Skip if REF and ALT are the same
        if i == 0:
            # Keep original metadata for the first SNP
            simple_rows.append([chrom, int(pos) + i, ".", ref[i], alt[i]] + metadata.tolist() + ["original"])
        else:
            # Add metadata for split SNP
            simple_rows.append([chrom, int(pos) + i, ".", ref[i], alt[i]] + metadata.tolist() + ["splitted_SNP"])
    
    # Handle remaining bases if REF is longer (deletion)
    if len(ref) > min_len:
        for i in range(min_len, len(ref)):
            simple_rows.append([chrom, int(pos) + i, ".", ref[i], "-"] + metadata.tolist() + ["splitted_SNP"])
    
    # Handle remaining bases if ALT is longer (insertion)
    elif len(alt) > min_len:
        insertion = alt[min_len:]  # Remaining ALT bases
        insertion_pos = f"{pos}-{int(pos)+1}"  # Position between REF bases
        simple_rows.append([chrom, insertion_pos, ".", "-", insertion] + metadata.tolist() + ["splitted_SNP"])

    return simple_rows

def process_file(input_file, output_file):
    # Load the input file
    with open(input_file, 'r') as file:
        lines = file.readlines()
    
    # Filter out metadata lines (lines starting with '#')
    metadata_lines = [line for line in lines if line.startswith('#')]
    data_lines = [line for line in lines if not line.startswith('#')]
    
    # Check for column names in the last metadata line
    column_names = metadata_lines[-1].strip().split('\t') if metadata_lines else None
    
    # Parse data into a DataFrame
    data = pd.DataFrame([line.strip().split('\t') for line in data_lines])
    
    if column_names:
        # Ensure the number of column names matches the data
        if len(column_names) != data.shape[1]:
            print(f"Warning: Column names ({len(column_names)}) do not match the number of data columns ({data.shape[1]}). Adjusting automatically.")
            column_names = [f"col_{i}" for i in range(data.shape[1])]
    else:
        column_names = [f"col_{i}" for i in range(data.shape[1])]

    # Replace the "RO" column with "RO" and append "SPLIT_STATUS" in the header
    if "RO" in column_names:
        column_names[column_names.index("RO")] = "RO"  # Ensure RO is intact
        column_names.append("SPLIT_STATUS")  # Add SPLIT_STATUS as a new column
    else:
        column_names.append("SPLIT_STATUS")

    # Ensure the DataFrame matches the updated header
    data.columns = column_names[:data.shape[1]]  # Ensure header matches data shape

    # Identify metadata columns (everything after the 5th column)
    metadata_columns = data.columns[5:]
    
    # Apply the splitting logic to all rows
    split_rows = []
    for _, row in data.iterrows():
        split_rows.extend(split_snps(row, metadata_columns))
    
    # Convert the list of split rows back into a DataFrame
    split_data = pd.DataFrame(split_rows, columns=column_names)
    
    # Write the result back to a new file
    with open(output_file, 'w') as output:
        # Modify the header to reflect the changes
        modified_header = "\t".join(column_names) + "\n"
        output.writelines(metadata_lines[:-1])  # Write all metadata except the last header
        output.write(modified_header)          # Write the modified header
        split_data.to_csv(output, sep='\t', index=False, header=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split all SNPs into simple SNPs in a VCF file.")
    parser.add_argument("-i", "--input", required=True, help="Input VCF file")
    parser.add_argument("-o", "--output", required=True, help="Output VCF file")
    args = parser.parse_args()
    
    process_file(args.input, args.output)
