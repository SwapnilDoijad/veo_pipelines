
import sys
import os
import pandas as pd
import argparse

# Parse the flags
parser = argparse.ArgumentParser()
parser.add_argument("-o", "--otus", help="Output directory", nargs='+', type=str)
args = parser.parse_args()

# Store the files in variable
file = args.otus

with open(file[0], 'r') as f:
    files = [i.strip() for i in f.readlines()]

# Initialize a dictionary to store the otus
# Keys= taxonomic assignments of OTUs
otus = {}
files_used = []

# Iterate through all files
for i in files:
    print(i)
    # Sample name comes from the structured download
    sample_name = i.split('/')[-1].split("_")[0]
    # Check if the MGnify pipeline is the first one
    if "1.0" in i.split('/'):
        continue
    # Read the otu file
    df = pd.read_csv(i, sep='\t', header=0, skiprows=1)
    if "taxonomy" not in df.columns:
        continue
    # Iterate through the found taxa
    for tax in df["taxonomy"]:
        # Initialize a dictionary for every new taxonomy found
        # Keys= sample names, values= abundance
        if tax not in otus.keys():
            otus[tax] = {}
        # For every taxon found, a dictionary as above is created
        otus[tax][sample_name] = df[df["taxonomy"] == tax][sample_name].sum()
    files_used.append(i)

# Convert the dictionary as a pandas Dataframe
# Transpose the dataframe, to have the samples as columns
df = pd.DataFrame(otus).T

# Add 0, in the taxa that were not found in a sample
df = df.fillna(0)

# Write the final OTU Table to a tsv file!
df.to_csv('merged.tsv', sep='\t')

with open('Files_used_for_OTU_Table.txt', 'w') as g:
    for j in files_used:
        g.write(j + '\n')

print("All files were parsed, thank you for your patience")
