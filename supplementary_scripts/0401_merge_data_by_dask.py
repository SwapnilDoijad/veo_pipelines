import os
import argparse
import pandas as pd
import dask.dataframe as dd

def merge_files(input_folder, output_file):
    # Create a dask dataframe to store intermediate results
    dask_dfs = []

    # Iterate over each file in the input folder
    for filename in os.listdir(input_folder):
        if filename.endswith('.dump'):
            file_path = os.path.join(input_folder, filename)
            print(file_path)  # Debugging statement
            # Read data from the file into a dask DataFrame
            dask_df = dd.read_csv(file_path, sep=' ', header=None, names=['Sequence', 'Count'], dtype={'Sequence': str, 'Count': int})
            # Extract the filename without extension and use it as a new_name for the column name
            new_name = os.path.splitext(filename)[0].replace(".fasta.jf", "")
            dask_df = dask_df.rename(columns={'Count': f'{new_name}'})
            dask_dfs.append(dask_df)

    if not dask_dfs:
        print("No suitable files found in the input folder.")  # Debugging statement
        return

    print("Merging files...")  # Debugging statement
    # Concatenate the dask DataFrames along the 'Sequence' column
    concatenated_dask_df = dd.concat(dask_dfs)

    print("Grouping and summing...")  # Debugging statement
    # Group by 'Sequence' and sum the counts
    merged_dask_df = concatenated_dask_df.groupby('Sequence').sum()

    print("Computing the result...")  # Debugging statement
    # Compute the result
    merged_df = merged_dask_df.compute()

    # If merged_df is empty, return
    if merged_df.empty:
        print("Merged DataFrame is empty.")
        return

    print("Transposing the DataFrame...")  # Debugging statement
    # Transpose the DataFrame
    merged_df = merged_df.T

    print("Filling NaN values with 0 and converting to integers...")  # Debugging statement
    # Convert values to integers
    merged_df = merged_df.fillna(0).astype(int)

    print("Writing the DataFrame to a matrix file...")  # Debugging statement
    # Write the DataFrame to a matrix file
    merged_df.to_csv(output_file, sep='\t', header=True, index=True, index_label='File_ID')
    print(f"Matrix file '{output_file}' saved successfully.")  # Debugging statement

if __name__ == "__main__":
    # Create argument parser
    parser = argparse.ArgumentParser(description="Merge data files into a matrix.")

    # Add arguments
    parser.add_argument("-i", "--input", type=str, help="Input folder containing data files.", required=True)
    parser.add_argument("-o", "--output", type=str, help="Output file path for the matrix.", required=True)

    # Parse arguments
    args = parser.parse_args()

    # Call merge_files function with provided arguments
    merge_files(args.input, args.output)
