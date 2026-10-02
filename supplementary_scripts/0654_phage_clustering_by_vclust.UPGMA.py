#!/usr/bin/env python3
import sys
import argparse
import pandas as pd
import matplotlib.pyplot as plt

from scipy.cluster.hierarchy import linkage, dendrogram, to_tree
from scipy.spatial.distance import squareform
from scipy.cluster.hierarchy import leaves_list

sys.setrecursionlimit(10000)

def get_newick(node, parent_dist, leaf_names, newick=""):
    """
    Convert scipy cluster tree to Newick.
    """
    if node.is_leaf():
        return "%s:%.6f%s" % (
            leaf_names[node.id],
            parent_dist - node.dist,
            newick,
        )
    else:
        if len(newick) > 0:
            newick = "):%.6f%s" % (parent_dist - node.dist, newick)
        else:
            newick = ");"

        newick = get_newick(
            node.get_left(),
            node.dist,
            leaf_names,
            newick=newick,
        )

        newick = get_newick(
            node.get_right(),
            node.dist,
            leaf_names,
            newick="," + newick,
        )

        newick = "(" + newick

        return newick


def main():

    parser = argparse.ArgumentParser(
        description="Create UPGMA tree from distance matrix"
    )

    parser.add_argument(
        "-i",
        "--input",
        required=True,
        help="Distance matrix TSV"
    )

    parser.add_argument(
        "-o",
        "--outprefix",
        required=True,
        help="Output prefix"
    )

    args = parser.parse_args()

    # read matrix
    dist = pd.read_csv(
        args.input,
        sep="\t",
        index_col=0
    )

    # convert to condensed form required by scipy
    condensed = squareform(dist.values)

    # UPGMA = average linkage
    Z = linkage(condensed, method="average")

    # Get UPGMA leaf order
    leaf_order = leaves_list(Z)

    ordered_ids = dist.index[leaf_order][::-1]

    with open(f"{args.outprefix}.leaf_order.txt", "w") as f:
        for genome in ordered_ids:
            f.write(f"{genome}\n")

    print(f"Leaf order written to: {args.outprefix}.leaf_order.txt")

    # save dendrogram only if not too many genomes
    if len(dist.index) <= 500:
        plt.figure(figsize=(20, 12))
        dendrogram(
            Z,
            labels=dist.index.tolist(),
            leaf_rotation=90,
            leaf_font_size=6
        )
        plt.tight_layout()
        plt.savefig(f"{args.outprefix}.png", dpi=300)
        plt.close()
        print(f"Dendrogram written to: {args.outprefix}.png")
    else:
        print(f"Skipping PNG dendrogram because {len(dist.index)} genomes are too many.")
        print("Use the Newick tree in iTOL instead.")

    # save Newick tree
    tree = to_tree(Z)

    newick = get_newick(
        tree,
        tree.dist,
        dist.index.tolist()
    )

    with open(f"{args.outprefix}.nwk", "w") as f:
        f.write(newick + "\n")

    print(f"Tree written to: {args.outprefix}.nwk")

if __name__ == "__main__":
    main()