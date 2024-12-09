import argparse
import gzip
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats
from sklearn.manifold import TSNE

# --- GC Content Analysis ---
def calculate_gc_content(fastq_file):
    """
    Calculate the GC content for each read in a FASTQ file, ignoring masked bases (N).
    """
    gc_content = []
    read_ids = []
    
    with gzip.open(fastq_file, 'rt') as f:
        for i, line in enumerate(f):
            if i % 4 == 0:  # Read ID
                read_ids.append(line.strip()[1:])  # Skip '@' symbol
            elif i % 4 == 1:  # Sequence line
                sequence = line.strip()
                gc = sequence.count('G') + sequence.count('C')
                valid_bases = sequence.count('A') + sequence.count('T') + sequence.count('G') + sequence.count('C')
                if valid_bases > 0:
                    gc_content.append((gc / valid_bases) * 100)
                else:
                    gc_content.append(0)  # Handle cases where all bases are masked
    # Remove '@' from the start of each read_id
    read_ids = [read_id.lstrip('@') for read_id in read_ids]
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
    return (np.array(gc_content) < lower_bound) | (np.array(gc_content) > upper_bound)

# --- t-SNE Analysis ---
def perform_tsne(matrix_file, output_dir):
    """
    Perform t-SNE on the matrix file and ensure the output contains 'Read_ID' and t-SNE components.
    """
    # Load the matrix file
    df = pd.read_csv(matrix_file, sep='\t', index_col=0)  # Read IDs are assumed to be the index

    # Perform t-SNE dimensionality reduction
    tsne = TSNE(n_components=2, random_state=42)
    tsne_result = tsne.fit_transform(df.values)

    # Create a new DataFrame for t-SNE results
    tsne_df = pd.DataFrame({
        'Read_ID': df.index,  # Retain original IDs
        't-SNE_Component_1': tsne_result[:, 0],
        't-SNE_Component_2': tsne_result[:, 1]
    })

    # Save t-SNE results
    tsne_file = os.path.join(output_dir, 'tsne_coordinates.tsv')
    tsne_df.to_csv(tsne_file, sep='\t', index=False)
    print(f"t-SNE results saved: {tsne_file}")

    return tsne_df

def save_gc_content_results(read_ids, gc_content, gc_outliers, output_dir):
    """
    Save GC content analysis results to a file, ensuring Read_IDs match the format in tsne_coordinates.tsv
    and removing duplicates.
    """
    # Strip metadata from Read_IDs (everything after the first space)
    stripped_read_ids = [read_id.split()[0].strip() for read_id in read_ids]

    # Create a DataFrame for GC content results
    gc_results = pd.DataFrame({
        'Read_ID': stripped_read_ids,  # Use stripped Read_IDs
        'GC_Content': gc_content,
        'GC_Outlier': gc_outliers
    })

    # Drop duplicate Read_IDs, keeping the first occurrence
    gc_results = gc_results.drop_duplicates(subset='Read_ID', keep='first')

    # Save the GC content results
    gc_file = os.path.join(output_dir, 'gc_content_results.tsv')
    gc_results.to_csv(gc_file, sep='\t', index=False)
    print(f"GC content results saved (duplicates removed): {gc_file}")





def identify_tsne_outliers(tsne_df, zscore_threshold=2):
    """
    Identify outliers in t-SNE results using Z-scores and add the Zscore_Outlier column to the DataFrame.
    """
    # Calculate Z-scores for t-SNE components
    tsne_df['X_zscore'] = stats.zscore(tsne_df['t-SNE_Component_1'])
    tsne_df['Y_zscore'] = stats.zscore(tsne_df['t-SNE_Component_2'])

    # Add the Zscore_Outlier column to tsne_df
    tsne_df['Zscore_Outlier'] = (abs(tsne_df['X_zscore']) > zscore_threshold) | \
                                 (abs(tsne_df['Y_zscore']) > zscore_threshold)

# --- Save Results ---
def save_combined_outliers(tsne_df, output_dir):
    """
    Save combined outlier data with GC and Z-score flags, including read IDs as the first column.
    """
    combined_file = os.path.join(output_dir, 'combined_outliers.tsv')

    # Ensure all required columns are present
    columns_to_save = ['Read_ID', 't-SNE_Component_1', 't-SNE_Component_2', 'GC_Outlier', 'Zscore_Outlier', 'Combined_Outlier']
    missing_columns = set(columns_to_save) - set(tsne_df.columns)
    if missing_columns:
        raise KeyError(f"The following required columns are missing: {missing_columns}")

    # Save the DataFrame with the required columns
    tsne_df[columns_to_save].to_csv(combined_file, sep='\t', index=False)
    print(f"Combined outliers saved: {combined_file}")


def save_tsne_coordinates(tsne_df, output_dir):
    """
    Save t-SNE coordinates, including Read_ID, and Z-score outlier flags to a file.
    """
    tsne_file = os.path.join(output_dir, 'tsne_coordinates.tsv')
    tsne_df[['Read_ID', 't-SNE_Component_1', 't-SNE_Component_2', 'Zscore_Outlier']].to_csv(tsne_file, sep='\t', index=False)
    print(f"t-SNE coordinates saved: {tsne_file}")


# --- Visualization ---
def visualize_combined(tsne_df, output_dir):
    """
    Visualize GC content and t-SNE outliers on the same t-SNE plot with descriptive labels in the legend.
    """
    # Assign descriptive labels instead of colors
    tsne_df['Legend_Label'] = 'inliers'  # Default: inliers
    tsne_df.loc[tsne_df['GC_Outlier'] & ~tsne_df['Zscore_Outlier'], 'Legend_Label'] = 'outlier: GC content'
    tsne_df.loc[~tsne_df['GC_Outlier'] & tsne_df['Zscore_Outlier'], 'Legend_Label'] = 'outlier: Z-Score'
    tsne_df.loc[tsne_df['Combined_Outlier'], 'Legend_Label'] = 'outlier: both'

    # Assign colors based on the labels
    color_map = {
        'inliers': 'blue',
        'outlier: GC content': 'green',
        'outlier: Z-Score': 'red',
        'outlier: both': 'black'
    }
    tsne_df['Color'] = tsne_df['Legend_Label'].map(color_map)

    # Plotting
    plt.figure(figsize=(8, 6))
    for label, group in tsne_df.groupby('Legend_Label'):
        plt.scatter(
            group['t-SNE_Component_1'], group['t-SNE_Component_2'],
            color=color_map[label], label=label, alpha=0.7
        )
    plt.xlabel('t-SNE_Component_1')
    plt.ylabel('t-SNE_Component_2')
    plt.title('t-SNE Inliers and Outliers')
    plt.legend(title='Outlier Type')
    plt.grid(True)
    plt.savefig(os.path.join(output_dir, 'tsne_combined_outliers_plot.png'))
    plt.close()

    print("t-SNE visualization saved.")


# --- Main Function ---
def main():
    parser = argparse.ArgumentParser(description="Analyze GC content and perform t-SNE dimensionality reduction.")
    parser.add_argument('-g', '--gc_input', type=str, help='Input FASTQ.gz file for GC content analysis', required=True)
    parser.add_argument('-m', '--matrix_input', type=str, help='Matrix file for t-SNE analysis', required=True)
    parser.add_argument('-o', '--output_dir', type=str, help='Output directory', required=True)
    parser.add_argument('--threshold', type=float, default=2, help='Z-score threshold for outlier detection')
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    # GC Content Analysis
    print("Calculating GC content...")
    read_ids, gc_content = calculate_gc_content(args.gc_input)
    gc_outliers = identify_gc_outliers(gc_content)

    # Save GC content results
    save_gc_content_results(read_ids, gc_content, gc_outliers, args.output_dir)

    # Perform t-SNE analysis
    print("Performing t-SNE analysis...")
    tsne_df = perform_tsne(args.matrix_input, args.output_dir)

    # Identify t-SNE outliers
    print("Identifying t-SNE outliers...")
    identify_tsne_outliers(tsne_df, args.threshold)

    # Add GC outliers to t-SNE DataFrame
    gc_outlier_map = {read_id.split()[0].strip(): outlier for read_id, outlier in zip(read_ids, gc_outliers)}
    tsne_df['GC_Outlier'] = tsne_df['Read_ID'].str.strip().map(gc_outlier_map).fillna(False).astype(bool)



    # Debugging: Check mismatches
    print("Sample Read_IDs in tsne_df:")
    print(tsne_df['Read_ID'].head())

    print("Sample Read_IDs in gc_outlier_map:")
    print(list(gc_outlier_map.keys())[:10])

    # Check missing IDs after mapping
    missing_ids = tsne_df.loc[~tsne_df['Read_ID'].isin(gc_outlier_map.keys()), 'Read_ID']
    print("Missing Read_IDs in mapping (after stripping metadata):")
    print(missing_ids.head())


    # Identify mismatched IDs
    missing_ids = tsne_df.loc[~tsne_df['Read_ID'].isin(gc_outlier_map.keys()), 'Read_ID']
    print("Missing Read_IDs in mapping:")
    print(missing_ids.head())


    # Combine Outliers
    tsne_df['Combined_Outlier'] = tsne_df['Zscore_Outlier'] & tsne_df['GC_Outlier']

    # Save outputs
    save_tsne_coordinates(tsne_df, args.output_dir)
    save_combined_outliers(tsne_df, args.output_dir)

    # Visualize combined outliers
    print("Visualizing combined outliers...")
    visualize_combined(tsne_df, args.output_dir)

    print(f"All results saved in {args.output_dir}")


if __name__ == "__main__":
    main()
