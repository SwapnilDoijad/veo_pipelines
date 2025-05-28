import argparse
import matplotlib.pyplot as plt
import numpy as np
import os

# Argument parser
parser = argparse.ArgumentParser(description='Generate histogram from input values.')
parser.add_argument('-i', '--input', type=str, required=True, help='Input file containing Length and Count values')
parser.add_argument('-r', '--range', type=int, required=True, help='Interval range for histogram bins')
args = parser.parse_args()

# Read data from input file, ignoring the header
values = []
with open(args.input, 'r') as f:
    next(f)  # Skip header line
    for line in f:
        parts = line.strip().split('\t')  # Assume tab-separated values
        if len(parts) == 2:
            try:
                length = int(parts[0])
                count = int(parts[1])
                values.extend([length] * count)  # Expand data by count
            except ValueError:
                continue  # Ignore invalid lines

# Define bins from 0 to max value + range to ensure full coverage
max_value = max(values) if values else 100000
bins = np.arange(0, max_value + args.range, args.range)

# Calculate histogram data
hist, bin_edges = np.histogram(values, bins=bins)

# Save histogram data to a .bin.tsv file
bin_output_file = f"{os.path.splitext(args.input)[0]}.bin.tsv"
with open(bin_output_file, 'w') as f:
    f.write("Range\tFrequency\n")
    for b, h in zip(bin_edges[:-1], hist):
        f.write(f"{b}-{b+args.range}\t{h}\n")

# Plot histogram
plt.figure(figsize=(12, 6))
plt.hist(values, bins=bins, edgecolor='black', alpha=0.7)
plt.xlabel("nucleotide-length (bp)")
plt.ylabel("number-of-seq")
plt.title("length distribution")
plt.grid(axis='y', alpha=0.75)

# Generate output file name with .png suffix
output_file = f"{os.path.splitext(args.input)[0]}.png"

# Save histogram to output file
plt.savefig(output_file)
plt.show()
