####  !!!!! WORKED !!!!! for 214161 files, with 350 GB memory and 90 CPU on interactive node
    ## in less than 9 hours  (52,360 x 214,162 matrix)
    ## python /home/groups/VEO/scripts_for_users/supplementary_scripts/m004_otus2matrix.py -i list.path_for_4.1_OTU_tsv.txt -o matrix.all_togther_by_tmux.tsv

import dask.dataframe as dd
import pandas as pd
import os
import argparse
import time
from collections import defaultdict

# Parse the flags
parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", help="Input file with OTU file paths", type=str, required=True)
parser.add_argument("-o", "--output", help="Output file for the merged TSV", type=str, required=True)
args = parser.parse_args()

# Store the files in variable
with open(args.input, 'r') as f:
    files = [i.strip() for i in f.readlines()]

# Initialize a defaultdict to store the OTUs
# Keys = taxonomic assignments of OTUs
otus = defaultdict(lambda: defaultdict(int))

# Total number of files
total_files = len(files)

# Start the timer
start_time = time.time()

# Process each file in chunks
for index, file_path in enumerate(files):
    print(f"Processing file {index + 1} of {total_files}")
    sample_name = os.path.basename(file_path).split("_")[0]
    
    # Read the OTU file in chunks using Dask
    dask_df = dd.read_csv(file_path, sep='\t', header=0, skiprows=1, assume_missing=True)
    if "taxonomy" not in dask_df.columns:
        continue
    
    # Process each chunk
    for chunk in dask_df.to_delayed():
        chunk = chunk.compute()
        for tax in chunk["taxonomy"].unique():
            tax_df = chunk[chunk["taxonomy"] == tax]
            otus[tax][sample_name] += tax_df[sample_name].sum()
    
    # Calculate elapsed time and estimate time remaining
    elapsed_time = time.time() - start_time
    time_per_file = elapsed_time / (index + 1)
    remaining_time = time_per_file * (total_files - (index + 1))
    remaining_time_str = time.strftime("%H:%M:%S", time.gmtime(remaining_time))
    print(f"Estimated time remaining: {remaining_time_str}")

# Convert the defaultdict to a DataFrame
otu_df = pd.DataFrame(otus).T.fillna(0).astype(int)

# Ensure all taxonomic assignments are represented for all samples
all_samples = set()
for sample_counts in otus.values():
    all_samples.update(sample_counts.keys())

otu_df = otu_df.reindex(columns=all_samples, fill_value=0)

# Write the DataFrame to the output file
otu_df.to_csv(args.output, sep='\t')

print("All files were parsed and the data was merged successfully.")
