import argparse
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

def plot_clustered_heatmap(input_file, output_file, drop_samples=None):
    # Load the data
    df = pd.read_csv(input_file, sep='\t', index_col=0)

    # Drop specified samples if the flag is provided
    if drop_samples:
        drop_ids = drop_samples.split(",")  # Split the comma-separated IDs
        df = df.drop(index=drop_ids, columns=[col for col in drop_ids if col in df.columns], errors='ignore')

    # Clean the data
    df_cleaned = df.drop(columns=[col for col in df.columns if "Unnamed" in col or df[col].isnull().all()])
    df_cleaned = df_cleaned.loc[df_cleaned.index.intersection(df_cleaned.columns)]
    df_cleaned = df_cleaned.apply(pd.to_numeric, errors='coerce').fillna(0)

    # Generate the clustermap
    sns.set(style="white")
    g = sns.clustermap(df_cleaned,
                       method='average',
                       metric='euclidean',
                       cmap="viridis",
                       figsize=(14, 14),
                       xticklabels=True,  # Display column labels
                       yticklabels=True)  # Display row labels

    # Add a title to the colorbar
    colorbar = g.ax_heatmap.collections[0].colorbar
    colorbar.set_label("Shared genome content", rotation=90, labelpad=10, fontsize=14)
    colorbar.ax.yaxis.set_label_position('left')
    colorbar.ax.yaxis.set_ticks_position('left')
    colorbar.ax.yaxis.set_label_coords(-1.5, 0.5) 

    # Manually layout to prevent legend overlap
    g.fig.suptitle("Clustered Heatmap with Dendrograms", y=1.02, fontsize=20)
    g.fig.subplots_adjust(top=0.95, bottom=0.05, left=0.05, right=0.95)

    g.cax.set_position([0.1, 0.8, 0.02, 0.1])  # [left, bottom, width, height]

    # Save the figure
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate clustered heatmap from matrix")
    parser.add_argument('-i', '--input', required=True, help='Input tab-delimited matrix file')
    parser.add_argument('-o', '--output', required=True, help='Output image file (e.g., .png, .jpg, .pdf)')
    parser.add_argument('--drop-samples', help='Comma-separated list of sample IDs to drop from the analysis', default=None)
    args = parser.parse_args()

    plot_clustered_heatmap(args.input, args.output, args.drop_samples)
