# source /home/groups/VEO/tools/python/pandas/bin/activate
# pip install matplotlib pandas

import argparse
import os
import pandas as pd
import matplotlib.pyplot as plt

# Argument parser for input and output file paths
parser = argparse.ArgumentParser(description='Create a stacked column chart from input data.')
parser.add_argument('-i', '--input', type=str, help='Input data file (e.g., input.tsv)', required=True)
parser.add_argument('-o', '--output', type=str, help='Output chart file (e.g., output.png)', required=True)
args = parser.parse_args()

# Extract the file names without extensions
input_filename = os.path.splitext(os.path.basename(args.input))[0]
output_filename = os.path.splitext(os.path.basename(args.output))[0]

# Read data from the input file using pandas
data = pd.read_csv(args.input, sep='\t', index_col='ids')

# Transpose the data to swap X and Y axes
data = data.transpose()

# Create a stacked column chart
ax = data.plot(kind='bar', stacked=True, figsize=(10, 6))

# Set the title of the chart to be the input and output file names
plt.title(f'{input_filename}')

# Customize the chart (you can adjust these as needed)
plt.xlabel('samples')  # X-axis label now corresponds to B columns
plt.ylabel('percentage_reads')     # Y-axis label corresponds to the IDs
plt.legend(title='Strain-IDs', bbox_to_anchor=(1.05, 1), loc='upper left')

# Save the chart as a PNG file
plt.savefig(args.output, bbox_inches='tight')

# Show the chart (optional)
plt.show()

