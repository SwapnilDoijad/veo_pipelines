import os
import argparse
import pandas as pd

def merge_files(input_folder, output_file):
    # Initialize merged DataFrame to None
    merged_df = None

    # Iterate over each file in the input folder
    for filename in os.listdir(input_folder):
        if filename.endswith('.dump'):
            file_path = os.path.join(input_folder, filename)
            print(file_path)  # Debugging statement
            # Read data from the file into a DataFrame
            df = pd.read_csv(file_path, sep=' ', header=None, names=['Sequence', 'Count'], dtype={'Sequence': str, 'Count': int})
            # Extract the filename without extension and use it as a new_name for the column name
            new_name = os.path.splitext(filename)[0].replace(".fasta.jf", "")
            df = df.rename(columns={'Count': f'{new_name}'})

            # If merged_df is None, assign df directly
            if merged_df is None:
                merged_df = df
            else:
                # Merge the DataFrame with the existing merged DataFrame
                merged_df = pd.merge(merged_df, df, on='Sequence', how='outer')

    if merged_df is None:
        print("No suitable files found in the input folder.")  # Debugging statement
        return

    # Set the 'Sequence' column as index
    merged_df.set_index('Sequence', inplace=True)
    
    # Fill missing values with 0 and round counts to the nearest integer
    merged_df = merged_df.fillna(0).round().astype(int)

    # Transpose the DataFrame
    merged_df = merged_df.T

    # Write the transposed DataFrame to a matrix file
    merged_df.to_csv(output_file, sep='\t', header=True, index=True, index_label='Sequence')

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
