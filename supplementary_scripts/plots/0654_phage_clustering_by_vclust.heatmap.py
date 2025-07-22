import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import argparse
import matplotlib.patches as mpatches
import numpy as np

def main(input_file, output_file, checkv_file=None):
    # Read cluster data
    df = pd.read_csv(input_file, sep="\t", header=0, names=["object", "Cluster"])
    df["object"] = df["object"].astype(str).str.strip()

    # Cluster frequencies
    cluster_counts = df['Cluster'].value_counts().sort_index()

    # Pivot for heatmap
    heatmap_pivot = pd.crosstab(df["object"], df["Cluster"])

    # Optional: checkv coloring
    checkv_colors = None
    if checkv_file:
        # Load CheckV table
        checkv_df = pd.read_csv(checkv_file, sep="\t", dtype=str)
        checkv_df.columns = [col.strip() for col in checkv_df.columns]
        checkv_df["contig_id"] = checkv_df["contig_id"].astype(str).str.strip()
        checkv_df["checkv_quality"] = checkv_df["checkv_quality"].astype(str).str.strip()

        # Drop rows with missing values
        checkv_df = checkv_df[["contig_id", "checkv_quality"]].dropna()

        # Build mapping
        checkv_quality_map = checkv_df.set_index("contig_id")["checkv_quality"].to_dict()

        # Color mapping
        quality_to_color = {
            "Complete": "#1a9850",
            "High-quality": "#66bd63",
            "Medium-quality": "#fee08b",
            "Low-quality": "#d73027",
            "Not-determined": "#d3d3d3",
        }

        checkv_colors = heatmap_pivot.copy()
        checkv_colors[:] = "white"

        unmatched_ids = []

        for obj in checkv_colors.index:
            quality = checkv_quality_map.get(obj)
            if quality is None:
                unmatched_ids.append(obj)
                quality = "Not-determined"
            color = quality_to_color.get(quality, "#d3d3d3")

            for cluster in checkv_colors.columns:
                if heatmap_pivot.loc[obj, cluster] == 1:
                    checkv_colors.loc[obj, cluster] = color

        # Debug: print unmatched IDs
        if unmatched_ids:
            print("\n⚠️ DEBUG: Unmatched objects (not found in CheckV file):")
            for obj in unmatched_ids:
                print(f" - {obj}")

    # Set up the figure
    fig = plt.figure(figsize=(12, 14))
    gs = fig.add_gridspec(2, 1, height_ratios=[1.5, 5], hspace=0.05)  # <-- smaller hspace
    ax_bar = fig.add_subplot(gs[0])
    ax_heatmap = fig.add_subplot(gs[1])

    # Barplot
    sns.barplot(x=cluster_counts.index, y=cluster_counts.values, ax=ax_bar, color='black', edgecolor=None, linewidth=0)
    ax_bar.set_ylabel('PhagesInCluster', fontsize=14)
    ax_bar.set_xlabel('')
    ax_bar.set_xticks([])
    # 🔥 Remove axis borders (spines)
    for spine in ax_bar.spines.values():
        spine.set_visible(False)

    # Heatmap
    if checkv_colors is not None:
        sns.heatmap(
            heatmap_pivot.astype(bool),
            cmap=["white"],
            cbar=False,
            ax=ax_heatmap,
            yticklabels=True,
            mask=~heatmap_pivot.astype(bool),
        )
        for y, obj in enumerate(checkv_colors.index):
            for x, cluster in enumerate(checkv_colors.columns):
                color = checkv_colors.loc[obj, cluster]
                if color != "white":
                    ax_heatmap.add_patch(plt.Rectangle((x, y), 1, 1, facecolor=color, edgecolor='gray'))
    else:
        bw_cmap = sns.color_palette(["white", "black"])
        sns.heatmap(heatmap_pivot, cmap=bw_cmap, cbar=False, ax=ax_heatmap, yticklabels=True)

    # X tick labels
    ax_heatmap.set_yticks(np.arange(len(heatmap_pivot.index)) + 0.5)
    ax_heatmap.set_yticklabels(heatmap_pivot.index)
    ax_heatmap.set_xticks(np.arange(len(heatmap_pivot.columns)) + 0.5)
    ax_heatmap.set_xticklabels(heatmap_pivot.columns, rotation=45, ha='right')


    ax_heatmap.set_xlabel('vclust Cluster', fontsize=14)
    ax_heatmap.set_ylabel('Phage IDs', fontsize=16)

    # Legend
    if checkv_colors is not None:
        legend_handles = [
            mpatches.Patch(color=color, label=quality)
            for quality, color in quality_to_color.items()
        ]
        ax_heatmap.legend(handles=legend_handles, title='CheckV Quality', bbox_to_anchor=(1.05, 1), loc='upper left')
    else:
        black_patch = mpatches.Patch(color='black', label='Present')
        white_patch = mpatches.Patch(color='white', label='Absent')
        ax_heatmap.legend(handles=[black_patch, white_patch], title='Cluster', bbox_to_anchor=(1.05, 1), loc='upper left')

    # Save plot
    plt.savefig(output_file, dpi=300,bbox_inches='tight', pad_inches=0.1, facecolor='white', edgecolor='none')
    print(f"✅ Figure saved to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate cluster barplot and heatmap.")
    parser.add_argument("-i", "--input", required=True, help="Input tab-separated file with two columns: object and Cluster")
    parser.add_argument("-o", "--output", required=True, help="Output image file (e.g., plot.png)")
    parser.add_argument("--color-by-checkv", metavar="CHECKV_FILE", help="Enable coloring by CheckV quality using the given tab-separated CheckV file")
    args = parser.parse_args()

    main(args.input, args.output, args.color_by_checkv)
