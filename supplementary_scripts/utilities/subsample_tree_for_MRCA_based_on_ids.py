#!/usr/bin/env python3

import argparse
from ete3 import Tree

def extract_subtree(input_tree, output_tree, strain_ids):
    # Load the Newick tree
    tree = Tree(input_tree, format=1)

    # Find the MRCA of the given strain IDs
    try:
        mrca = tree.get_common_ancestor(strain_ids)
    except Exception as e:
        print(f"[ERROR] Could not find MRCA for given IDs: {strain_ids}")
        print(e)
        return

    # Write the subtree rooted at the MRCA
    mrca.write(format=1, outfile=output_tree)
    print(f"[INFO] Subtree rooted at MRCA of {len(strain_ids)} taxa written to: {output_tree}")

def main():
    parser = argparse.ArgumentParser(description="Extract MRCA-based subtree from a Newick tree.")
    parser.add_argument("-i", "--input", required=True, help="Input Newick tree file")
    parser.add_argument("-ids", "--strain_ids", required=True, help="Text file with strain IDs (one per line)")
    parser.add_argument("-o", "--output", required=True, help="Output Newick file for the subtree")

    args = parser.parse_args()

    # Read strain IDs from file
    try:
        with open(args.strain_ids, "r") as f:
            strain_ids = [line.strip() for line in f if line.strip()]
    except Exception as e:
        print(f"[ERROR] Failed to read ID file: {args.strain_ids}")
        print(e)
        return

    # Extract subtree
    extract_subtree(args.input, args.output, strain_ids)

if __name__ == "__main__":
    main()
