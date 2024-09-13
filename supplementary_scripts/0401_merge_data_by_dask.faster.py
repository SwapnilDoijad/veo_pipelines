import os
import argparse
import pandas as pd
import dask.dataframe as dd
from dask import delayed
from dask.distributed import Client
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def is_file_empty(file_path):
    """Check if a file is empty."""
    return os.stat(file_path).st_size == 0

def align_dataframe_columns(df, columns):
    """Ensure DataFrame has the required columns, filling missing ones with 0."""
    return df.reindex(columns=columns, fill_value=0)

def merge_files(input_folder, output_file):
    dask_dfs = []
    all_columns = ['Sequence']  # Start with 'Sequence' as the main column

    # Iterate over files in the input folder
    for filename in os.listdir(input_folder):
        if filename.endswith('.dump'):
            file_path = os.path.join(input_folder, filename)
            if is_file_empty(file_path):
                logger.warning(f"Skipping empty file: {file_path}")
                continue

            logger.info(f"Processing file: {file_path}")
            dask_df = delayed(pd.read_csv)(file_path, sep=' ', header=None, names=['Sequence', 'Count'], dtype={'Sequence': str, 'Count': int})
            new_name = os.path.splitext(filename)[0].replace(".fasta.jf", "")
            
            # Rename the 'Count' column to the unique file-based column
            dask_df = delayed(dask_df.rename)(columns={'Count': f'{new_name}'})
            dask_dfs.append(dask_df)
            
            # Keep track of all unique columns
            all_columns.append(new_name)

    if not dask_dfs:
        logger.warning("No suitable files found in the input folder.")
        return

    logger.info("Aligning DataFrames...")
    aligned_dfs = [delayed(align_dataframe_columns)(df, all_columns) for df in dask_dfs]
    
    # Concatenate aligned DataFrames lazily
    concatenated_df = dd.from_delayed(aligned_dfs)

    logger.info("Repartitioning to avoid empty partitions...")
    concatenated_df = concatenated_df.repartition(npartitions=10)  # Adjust npartitions as needed

    logger.info("Grouping and summing...")
    merged_dask_df = concatenated_df.groupby('Sequence').sum()

    logger.info("Computing the result...")
    merged_df = merged_dask_df.compute()

    if merged_df.empty:
        logger.warning("Merged DataFrame is empty.")
        return

    logger.info("Transposing the DataFrame...")
    merged_df = merged_df.T

    logger.info("Filling NaN values with 0 and converting to integers...")
    merged_df = merged_df.fillna(0).astype(int)

    logger.info("Writing the DataFrame to a matrix file...")
    merged_df.to_csv(output_file, sep='\t', header=True, index=True, index_label='File_ID')
    logger.info(f"Matrix file '{output_file}' saved successfully.")

if __name__ == "__main__":
    # Create argument parser
    parser = argparse.ArgumentParser(description="Merge data files into a matrix.")

    # Add arguments
    parser.add_argument("-i", "--input", type=str, help="Input folder containing data files.", required=True)
    parser.add_argument("-o", "--output", type=str, help="Output file path for the matrix.", required=True)

    # Parse arguments
    args = parser.parse_args()

    # Start Dask distributed client
    client = Client()

    # Call merge_files function with provided arguments
    merge_files(args.input, args.output)
