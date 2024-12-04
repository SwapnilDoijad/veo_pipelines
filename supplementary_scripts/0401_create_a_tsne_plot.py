import argparse
import os
import pandas as pd
from scipy import stats
from sklearn.manifold import TSNE
import matplotlib.pyplot as plt
import numpy as np

def parse_input_file(input_file):
    data = []
    with open(input_file, 'r') as f:
        next(f)
        for line in f:
            parts = line.strip().split('\t')
            barcode = parts[0]
            counts = list(map(int, parts[1:]))
            data.append((barcode, counts))
    return data

def normalize_counts(counts):
    total_counts = np.sum(counts, axis=1)  # Calculate total counts for each read
    valid_counts = total_counts != 0  # Identify non-zero total counts
    normalized_counts = np.zeros_like(counts, dtype=float)  # Initialize normalized counts array

    # Normalize only valid (non-zero total) counts
    normalized_counts[valid_counts] = counts[valid_counts] / total_counts[valid_counts, np.newaxis]
    return normalized_counts, valid_counts

def detect_outliers(input_file, output_dir, zscore_threshold=2):
    # Load data from input file
    df = pd.read_csv(input_file, delimiter='\t')  # Assuming tab-separated file

    # Calculate z-scores for X and Y coordinates
    df['X_zscore'] = stats.zscore(df['t-SNE_Component_1'])
    df['Y_zscore'] = stats.zscore(df['t-SNE_Component_2'])

    # Filter out points with z-scores beyond the threshold
    outliers = df[(abs(df['X_zscore']) > zscore_threshold) | (abs(df['Y_zscore']) > zscore_threshold)]
    inliers = df[(abs(df['X_zscore']) <= zscore_threshold) & (abs(df['Y_zscore']) <= zscore_threshold)]

    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Write outliers and inliers to the output files
    outliers.to_csv(os.path.join(output_dir, 'outlier.tsv'), sep='\t', index=False)
    inliers.to_csv(os.path.join(output_dir, 'inlier.tsv'), sep='\t', index=False)

    # Plot outliers and inliers
    plt.figure(figsize=(8, 6))
    plt.scatter(inliers['t-SNE_Component_1'], inliers['t-SNE_Component_2'], color='blue', label='Inliers')
    plt.scatter(outliers['t-SNE_Component_1'], outliers['t-SNE_Component_2'], color='red', label='Outliers')
    plt.xlabel('t-SNE_Component_1')
    plt.ylabel('t-SNE_Component_2')
    plt.title('Inliers and Outliers')
    plt.legend()
    plt.grid(True)
    plt.savefig(os.path.join(output_dir, 'inliers_outliers_plot.png'))
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Perform t-SNE dimensionality reduction, detect outliers in t-SNE coordinates, and plot")
    parser.add_argument('-i', '--input', type=str, help='Input file containing barcode counts', required=True)
    parser.add_argument('-o', '--output_dir', type=str, help='Output directory', required=True)
    parser.add_argument('--threshold', type=float, default=2, help='Z-score threshold for outlier detection')

    args = parser.parse_args()

    # Perform t-SNE dimensionality reduction
    data = parse_input_file(args.input)
    barcodes = [d[0] for d in data]
    counts = np.array([d[1] for d in data])
    counts_normalized, valid_counts = normalize_counts(counts)  # Normalize counts

    # Filter barcodes and counts to only include valid (non-zero total) counts
    barcodes_valid = np.array(barcodes)[valid_counts]
    counts_normalized_valid = counts_normalized[valid_counts]

    tsne = TSNE(n_components=2, random_state=42)
    tsne_result = tsne.fit_transform(counts_normalized_valid)

    # Write t-SNE coordinates to a file
    with open(f'{args.output_dir}/tsne_coordinates.tsv', 'w') as f:
        f.write("Data_ID\tt-SNE_Component_1\tt-SNE_Component_2\n")
        for barcode, coords in zip(barcodes_valid, tsne_result):
            f.write(f"{barcode}\t{coords[0]}\t{coords[1]}\n")

    # Call function to detect outliers and plot
    detect_outliers(os.path.join(args.output_dir, 'tsne_coordinates.tsv'), args.output_dir, args.threshold)

if __name__ == "__main__":
    main()
