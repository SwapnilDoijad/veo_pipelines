from ete3 import Tree
import itertools
import argparse

def load_tree(newick_path):
    return Tree(newick_path, format=1)

def load_keep_list(filepath):
    with open(filepath) as f:
        return set(line.strip() for line in f if line.strip())

def compute_patristic_distances(tree, exclude_names):
    leaves = tree.get_leaves()
    distances = {}
    for leaf1, leaf2 in itertools.combinations(leaves, 2):
        # Only compute distances between at least one reference genome
        if leaf1.name in exclude_names and leaf2.name in exclude_names:
            continue
        dist = tree.get_distance(leaf1, leaf2)
        distances.setdefault(leaf1.name, {})[leaf2.name] = dist
        distances.setdefault(leaf2.name, {})[leaf1.name] = dist
    return distances

def cluster_by_distance(distances, threshold, exclude_names):
    seen = set()
    clusters = []

    for leaf in distances:
        if leaf in seen or leaf in exclude_names:
            continue
        cluster = {leaf}
        for other, dist in distances[leaf].items():
            if other not in exclude_names and dist < threshold:
                cluster.add(other)
        seen.update(cluster)
        clusters.append(cluster)
    return clusters

def prune_tree(tree, clusters, keep_always):
    keep = set(keep_always)
    keep.update(sorted(cluster)[0] for cluster in clusters)
    
    # Only keep those tips, and preserve tree structure
    tree.prune(list(keep), preserve_branch_length=True)
    return tree


def main():
    parser = argparse.ArgumentParser(description="Subsample reference genomes in a tree by patristic distance.")
    parser.add_argument("-i", "--input", required=True, help="Input Newick tree")
    parser.add_argument("-l", "--list", required=True, help="Text file with your genome IDs (one per line)")
    parser.add_argument("-d", "--distance", type=float, default=0.001, help="Patristic distance threshold")
    parser.add_argument("-o", "--output", default="pruned_tree.nwk", help="Output Newick file")

    args = parser.parse_args()

    keep_always = load_keep_list(args.list)
    tree = load_tree(args.input)
    distances = compute_patristic_distances(tree, keep_always)
    clusters = cluster_by_distance(distances, args.distance, keep_always)

    print(f"Total leaves: {len(tree.get_leaves())}")
    print(f"Keeping {len(keep_always)} of your genomes.")
    print(f"Clustering {len(clusters)} reference groups by distance < {args.distance}")

    pruned_tree = prune_tree(tree, clusters, keep_always)
    pruned_tree.write(format=1, outfile=args.output)
    print(f"Pruned tree written to {args.output}")

if __name__ == "__main__":
    main()
