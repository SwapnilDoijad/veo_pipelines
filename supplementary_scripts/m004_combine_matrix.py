## merging matrix 
    ## solution 1: 
    ##!!!!! WORKED !!!!! for 214161 files, with 350 GB memory and 90 CPU on interactive node
    ## in less than 9 hours  (52,360 x 214,162 matrix)


#########################################

import dask.dataframe as dd
import glob

# Path to the directory containing the TSV files
input_dir = 'results/m004_otu2matrix/raw_files/'

# List all TSV files in the directory
file_pattern = input_dir + '*.tsv'
tsv_files = glob.glob(file_pattern)

# Initialize an empty dask dataframe to store the merged results
merged_df = None

# Read and merge each TSV file
for file in tsv_files:
    # Read the TSV file with dask
    df = dd.read_csv(file, sep='\t', assume_missing=True, dtype=str).set_index('Unnamed: 0')

    # Merge the dataframes
    if merged_df is None:
        merged_df = df
    else:
        merged_df = dd.merge(merged_df, df, left_index=True, right_index=True, how='outer')

# Fill missing values with 0 and convert to integers
merged_df = merged_df.fillna(0).astype(int)

# Compute and save the merged dataframe to a final TSV file
output_file = 'results/m004_otu2matrix/merged_matrix_by_solution_1.tsv'
merged_df.compute().to_csv(output_file, sep='\t')

print(f"Merged file saved to {output_file}")

#########################################
