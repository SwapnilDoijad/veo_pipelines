import argparse
import gzip
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def calculate_gc_content(fastq_file):
    """
    Calculate the GC content for each read in a FASTQ file, ignoring masked bases (N).
    """
    gc_content = []
    read_ids = []
    
    with gzip.open(fastq_file, 'rt') as f:
        for i, line in enumerate(f):
            if i % 4 == 0:  # Read ID
                read_ids.append(line.strip()[1:].split()[0])  # Skip '@' symbol and take the first part
            elif i % 4 == 1:  # Sequence line
                sequence = line.strip()
                gc = sequence.count('G') + sequence.count('C')
                valid_bases = sequence.count('A') + sequence.count('T') + sequence.count('G') + sequence.count('C')
                if valid_bases > 0:
                    gc_content.append((gc / valid_bases) * 100)
                else:
                    gc_content.append(0)  # Handle cases where all bases are masked
    return read_ids, gc_content

def identify_gc_outliers(gc_content):
    """
    Identify outliers in GC content using the IQR method.
    """
    q1 = np.percentile(gc_content, 25)
    q3 = np.percentile(gc_content, 75)
    iqr = q3 - q1
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    outliers = (gc_content < lower_bound) | (gc_content > upper_bound)
    return outliers

def save_results(output_dir, read_ids, gc_content, outliers):
    """
    Save results to output files and generate a plot.
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Save all results to a tab-separated file
    results = pd.DataFrame({
        "Read_ID": read_ids,
        "GC_Content": gc_content,
        "Outlier": outliers
    })
    tsv_file = os.path.join(output_dir, "iqr_gc_content_results.tsv")
    results.to_csv(tsv_file, sep='\t', index=False)
    
    print(f"Results saved: {tsv_file}")
    
    # Save only outlier IDs to a text file
    outlier_ids = [read_ids[i] for i in range(len(read_ids)) if outliers[i]]
    outlier_file = os.path.join(output_dir, "iqr_gc_content_outliers.txt")
    with open(outlier_file, 'w') as f:
        f.write("\n".join(outlier_ids))
    
    print(f"Outlier IDs saved: {outlier_file}")

def plot_results(output_dir, gc_content, outliers):
    """
    Generate plots for GC content distribution and save them.
    """
    os.makedirs(output_dir, exist_ok=True)

    # Histogram with outliers
    plt.figure(figsize=(10, 6))
    plt.hist(gc_content, bins=50, alpha=0.7, label='GC Content')
    plt.axvline(np.mean(gc_content), color='blue', linestyle='--', label='Mean')
    plt.scatter(
        [gc_content[i] for i in range(len(gc_content)) if outliers[i]], 
        [0] * sum(outliers),
        color='red', label='Outliers', alpha=0.7, zorder=5
    )
    plt.xlabel("GC Content (%)")
    plt.ylabel("Frequency")
    plt.title("GC Content Distribution (IQR Method)")
    plt.legend()
    plt.grid(True)
    histogram_file = os.path.join(output_dir, "iqr_gc_content_histogram.png")
    plt.savefig(histogram_file)
    plt.close()

    # Box plot
    plt.figure(figsize=(8, 5))
    plt.boxplot(gc_content, vert=False, patch_artist=True, boxprops=dict(facecolor='lightblue'))
    plt.scatter(
        [gc_content[i] for i in range(len(gc_content)) if outliers[i]],
        [1] * sum(outliers),
        color='red', label='Outliers', alpha=0.7, zorder=5
    )
    plt.xlabel("GC Content (%)")
    plt.title("GC Content Box Plot (IQR Method)")
    plt.grid(True)
    boxplot_file = os.path.join(output_dir, "iqr_gc_content_boxplot.png")
    plt.savefig(boxplot_file)
    plt.close()

    print(f"Plots saved:")
    print(f" - Histogram: {histogram_file}")
    print(f" - Boxplot: {boxplot_file}")

def main():
    parser = argparse.ArgumentParser(description="Calculate GC content, identify outliers, and save results.")
    parser.add_argument('-i', '--input', type=str, help='Input FASTQ.gz file', required=True)
    parser.add_argument('-o', '--output_dir', type=str, help='Output directory', required=True)
    args = parser.parse_args()

    print("Calculating GC content...")
    read_ids, gc_content = calculate_gc_content(args.input)

    print("Identifying outliers using IQR...")
    outliers = identify_gc_outliers(gc_content)
    save_results(args.output_dir, read_ids, gc_content, outliers)
    plot_results(args.output_dir, gc_content, outliers)

    print(f"All results and plots saved in {args.output_dir}")

if __name__ == "__main__":
    main()
