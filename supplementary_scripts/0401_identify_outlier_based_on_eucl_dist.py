import argparse
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import seaborn as sns
from scipy.signal import find_peaks

def load_kmer_matrix(input_file):
    """Load the k-mer matrix from a given file."""
    df = pd.read_csv(input_file, sep="\t")
    return df

def normalize_kmer_matrix(df):
    """Normalize the k-mer matrix as percentages: value * 100 / sum of the row."""
    ids = df[df.columns[0]]  # Extract the first column (IDs)
    numeric_df = df.drop(columns=[df.columns[0]])
    row_sums = numeric_df.sum(axis=1)
    normalized_df = numeric_df.div(row_sums, axis=0) * 100
    normalized_df.insert(0, df.columns[0], ids)  # Add the IDs column back
    return normalized_df

def calculate_row_deviation(df):
    """Calculate row-wise deviation from column means using Euclidean distance."""
    ids = df[df.columns[0]]  # Extract the first column (IDs)
    numeric_df = df.drop(columns=[df.columns[0]])
    column_means = numeric_df.mean(axis=0)
    deviations = numeric_df.apply(lambda row: np.sqrt(((row - column_means) ** 2).sum()), axis=1)
    return deviations, ids

def calculate_average_deviation(deviations):
    """Calculate the average deviation for each Euclidean distance."""
    avg_deviation = deviations - deviations.mean()
    return avg_deviation

def determine_density_drop_threshold(avg_deviation):
    """Determine threshold based on the density drop-off point."""
    kde = sns.kdeplot(avg_deviation, bw_adjust=0.5).get_lines()[0].get_data()
    x, y = kde[0], kde[1]

    # Find peaks (high density) and valleys (density drops)
    peaks, _ = find_peaks(y)
    valleys, _ = find_peaks(-y)

    # Set threshold at first valley after the main peak
    if len(peaks) > 0 and len(valleys) > 0:
        main_peak = peaks[0]
        for valley in valleys:
            if valley > main_peak:
                threshold = x[valley]
                print(f"Threshold determined at density drop-off point: {threshold}")
                return threshold

    # Fallback threshold (99th percentile) if no clear drop found
    threshold = np.percentile(avg_deviation, 99)
    print(f"Fallback threshold (99th percentile): {threshold}")
    return threshold

def identify_unusual_reads(df, output_dir):
    """Identify reads (rows) with large deviations from the column mean profile."""
    os.makedirs(output_dir, exist_ok=True)  # Ensure output directory exists

    deviations, ids = calculate_row_deviation(df)
    avg_deviation = calculate_average_deviation(deviations)

    # Determine threshold based on density drop
    threshold_value = determine_density_drop_threshold(avg_deviation)

    # Identify outlier and inlier indices
    outlier_indices = avg_deviation > threshold_value
    inlier_indices = ~outlier_indices

    # Save Euclidean distances and average deviation to file
    ed_output_file = os.path.join(output_dir, "euclidean_distance.txt")
    result_df = pd.DataFrame({
        "File_ID": ids,
        "Euclidean_Distance": deviations,
        "Average_Euclidean_Distance": avg_deviation
    })
    result_df.to_csv(ed_output_file, sep="\t", index=False)
    print(f"Euclidean distances saved to {ed_output_file}")

    # Save outlier IDs to a separate file
    outliers_file = os.path.join(output_dir, "euclidean_distance.outlier.txt")
    ids[outlier_indices].to_csv(outliers_file, sep="\t", index=False, header=False)
    print(f"Outlier IDs saved to {outliers_file}")

    # Save inlier IDs to a separate file
    inliers_file = os.path.join(output_dir, "euclidean_distance.inlier.txt")
    ids[inlier_indices].to_csv(inliers_file, sep="\t", index=False, header=False)
    print(f"Inlier IDs saved to {inliers_file}")

    # Plot combined scatter and density plot
    scatter_density_plot_file = os.path.join(output_dir, "euclidean_distance.scatter_density.png")
    fig, ax = plt.subplots(figsize=(10, 6))
    grid = plt.GridSpec(1, 2, width_ratios=[3, 1])

    # Scatter plot on the left
    plt.subplot(grid[0])
    plt.scatter(range(len(avg_deviation)), avg_deviation, 
                c=['red' if val > threshold_value else 'blue' for val in avg_deviation],
                alpha=0.7, label='Reads')
    plt.axhline(threshold_value, color='red', linestyle='dashed', linewidth=1, label=f'Threshold')
    plt.title('Scatter Plot of Average Euclidean Distance')
    plt.xlabel('Row Index (Reads)')
    plt.ylabel('Average Euclidean Distance')
    plt.legend()
    plt.grid(alpha=0.75)

    # Density plot on the right
    plt.subplot(grid[1])
    sns.kdeplot(y=avg_deviation, color='blue', alpha=0.7, label='Density')
    plt.axhline(threshold_value, color='red', linestyle='dashed', linewidth=1)
    plt.title('Density')
    plt.xlabel('Density')
    plt.yticks([])

    plt.tight_layout()
    plt.savefig(scatter_density_plot_file)
    print(f"Scatter and density plot saved to {scatter_density_plot_file}")
    plt.close()

def main():
    parser = argparse.ArgumentParser(description="Identify contaminant reads based on deviation from k-mer column means.")
    parser.add_argument("--input_file", required=True, help="Path to the input k-mer matrix file (tab-separated).")
    parser.add_argument("--output_dir", required=True, help="Directory to save the output files.")

    args = parser.parse_args()

    # Load k-mer matrix
    kmer_matrix = load_kmer_matrix(args.input_file)

    # Normalize the k-mer matrix
    print("Normalizing k-mer matrix...")
    normalized_matrix = normalize_kmer_matrix(kmer_matrix)

    # Save the normalized matrix to a file
    normalized_output_file = os.path.join(args.output_dir, "euclidean_distance.normalized_matrix.txt")
    os.makedirs(args.output_dir, exist_ok=True)
    normalized_matrix.to_csv(normalized_output_file, sep="\t", index=False)
    print(f"Normalized matrix saved to {normalized_output_file}")

    # Identify and save unusual profiles with automatically determined threshold
    identify_unusual_reads(normalized_matrix, args.output_dir)

if __name__ == "__main__":
    main()
