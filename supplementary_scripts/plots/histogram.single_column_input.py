import argparse
import matplotlib.pyplot as plt
import numpy as np
import os

# Argument parser
parser = argparse.ArgumentParser(description='Generate histogram from input values.')
parser.add_argument('-i', '--input', type=str, required=True, help='Input file containing values')
parser.add_argument('-r', '--range', type=int, required=True, help='Interval range for histogram bins')
args = parser.parse_args()

## input should be a single column file with values
    # 5000
    # 12000
    # 15000
    # 22000
    # 32000
    # 50000
    # 75000
    # 95000


# Read data from input file, ignoring non-numeric lines
values = []
with open(args.input, 'r') as f:
    for line in f:
        try:
            values.append(int(line.strip()))
        except ValueError:
            continue  # Ignore lines that cannot be converted to integers

# Define bins from 0 to 100000 in steps of user-defined range
bins = np.arange(0, 100001, args.range)

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
plt.title("Phage genome length distribution")
plt.grid(axis='y', alpha=0.75)

# Generate output file name with .png suffix
output_file = f"{os.path.splitext(args.input)[0]}.png"

# Save histogram to output file
plt.savefig(output_file)
plt.show()

