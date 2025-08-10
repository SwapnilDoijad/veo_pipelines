import pandas as pd
import argparse
import matplotlib.pyplot as plt

def main():
    p = argparse.ArgumentParser(description="Relative abundance stacked bar chart from matrix TSV.")
    p.add_argument("-i", "--input", required=True, help="Input TSV (rows=taxa, cols=samples)")
    p.add_argument("-o", "--output", required=True, help="Output image path, e.g. plot.png")
    p.add_argument("--top-n", type=int, default=20, help="Number of most abundant taxa to keep (others grouped)")
    args = p.parse_args()

    # Read matrix (tab-separated). First column is taxon names.
    df = pd.read_csv(args.input, sep="\t")
    df = df.rename(columns={df.columns[0]: "Taxon"}).set_index("Taxon")
    df = df.apply(pd.to_numeric, errors="coerce").fillna(0)

    # Normalize to relative abundance per sample
    col_sums = df.sum(axis=0)
    col_sums[col_sums == 0] = 1
    df_rel = df.divide(col_sums, axis=1)

    # Pick top taxa by max abundance across samples; group rest into "Other"
    order = df_rel.max(axis=1).sort_values(ascending=False)
    top_taxa = order.head(args.top_n).index.tolist()
    df_top = df_rel.loc[top_taxa]
    if len(order) > args.top_n:
        df_other = pd.DataFrame([df_rel.drop(top_taxa).sum(axis=0)], index=["Other"])
        df_plot = pd.concat([df_top, df_other], axis=0)
    else:
        df_plot = df_top

    # Prepare for plotting (samples on x-axis)
    df_plot_t = df_plot.transpose()

    # Ensure "Other" is last in plotting order
    taxa_order = [t for t in df_plot_t.columns if t != "Other"]
    if "Other" in df_plot_t.columns:
        taxa_order.append("Other")

    fig, ax = plt.subplots(figsize=(10, 6))
    bottom = None
    handles = []
    labels = []
    for taxon in taxa_order:
        vals = df_plot_t[taxon]
        if taxon == "Other":
            color = "grey"
        else:
            color = None  # Let matplotlib choose
        bar = ax.bar(df_plot_t.index, vals, bottom=bottom, label=taxon, color=color)
        handles.append(bar)
        labels.append(taxon)
        if bottom is None:
            bottom = vals.copy()
        else:
            bottom = bottom + vals

    ax.set_ylabel("Relative abundance")
    ax.set_xlabel("Samples")
    ax.set_title("Relative Abundance (stacked)")
    
    # Reverse legend order so it matches top-to-bottom stack
    ax.legend(handles[::-1], labels[::-1], bbox_to_anchor=(1.02, 1), loc="upper left", title="Taxa")

    # Tilt x-axis labels to 45 degrees
    plt.xticks(rotation=45, ha="right")

    plt.tight_layout()
    plt.savefig(args.output, dpi=200, bbox_inches="tight")

if __name__ == "__main__":
    main()
