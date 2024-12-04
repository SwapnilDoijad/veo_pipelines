import pandas as pd
import argparse

def split_complex_snps(row, metadata_columns):
    chrom, pos, ref, alt = row[0], row[1], row[3], row[4]
    metadata = row[5:]
    simple_rows = []

    # Check for complex SNPs using the TYPE column
    if row["TYPE"] == "complex":
        min_len = min(len(ref), len(alt))
        
        # Process substitution for overlapping bases
        for i in range(min_len):
            if ref[i] == alt[i]:
                continue  # Skip if REF and ALT are the same
            if i == 0:
                # Keep original metadata for the first SNP
                simple_rows.append([chrom, int(pos) + i, ".", ref[i], alt[i]] + metadata.tolist())
            else:
                # Replace metadata with "splitted_*" for subsequent SNPs
                splitted_metadata = ["splitted_" + str(pos)] * len(metadata_columns)
                simple_rows.append([chrom, int(pos) + i, ".", ref[i], alt[i]] + splitted_metadata)
        
        # Handle remaining bases if REF is longer (deletion)
        if len(ref) > min_len:
            for i in range(min_len, len(ref)):
                if ref[i] == "-":
                    continue  # Skip if REF and ALT are the same
                splitted_metadata = ["splitted_" + str(pos)] * len(metadata_columns)
                simple_rows.append([chrom, int(pos) + i, ".", ref[i], "-"] + splitted_metadata)
        
        # Handle remaining bases if ALT is longer (insertion)
        elif len(alt) > min_len:
            for i in range(min_len, len(alt)):
                if alt[i] == "-":
                    continue  # Skip if REF and ALT are the same
                splitted_metadata = ["splitted_" + str(pos)] * len(metadata_columns)
                simple_rows.append([chrom, int(pos), ".", "-", alt[i]] + splitted_metadata)
    else:
        # If not complex, keep the row unchanged
        if ref != alt:  # Skip if REF and ALT are the same
            simple_rows.append(row.tolist())
    
    return simple_rows

def process_file(input_file, output_file):
    # Load the input file
    with open(input_file, 'r') as file:
        lines = file.readlines()
    
    # Filter out metadata lines (lines starting with '#')
    metadata_lines = [line for line in lines if line.startswith('#')]
    data_lines = [line for line in lines if not line.startswith('#')]
    
    # Check for column names in the last metadata line, otherwise use default
    column_names = metadata_lines[-1].strip().split('\t') if metadata_lines else None
    
    # Parse data into a DataFrame
    data = pd.DataFrame([line.strip().split('\t') for line in data_lines])
    
    if column_names:
        # Ensure the number of column names matches the data
        if len(column_names) != data.shape[1]:
            print("Warning: Column names do not match the number of data columns. Using default column names.")
            column_names = [f"col_{i}" for i in range(data.shape[1])]
    else:
        column_names = [f"col_{i}" for i in range(data.shape[1])]
    
    data.columns = column_names

    # Identify metadata columns
    metadata_columns = data.columns[5:]
    
    # Apply the splitting logic to all rows
    split_rows = []
    for _, row in data.iterrows():
        split_rows.extend(split_complex_snps(row, metadata_columns))
    
    # Convert the list of split rows back into a DataFrame
    split_data = pd.DataFrame(split_rows, columns=column_names)
    
    # Write the result back to a new file
    with open(output_file, 'w') as output:
        output.writelines(metadata_lines)  # Add the metadata lines back
        split_data.to_csv(output, sep='\t', index=False, header=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split complex SNPs into simple SNPs in a VCF file.")
    parser.add_argument("-i", "--input", required=True, help="Input VCF file")
    parser.add_argument("-o", "--output", required=True, help="Output VCF file")
    args = parser.parse_args()
    
    process_file(args.input, args.output)
