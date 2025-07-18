import argparse
from ete3 import Tree

def main():
    parser = argparse.ArgumentParser(description="Extract subtree from S1 to S2 based on MRCA")
    parser.add_argument("-i", "--input", required=True, help="Input Newick tree file")
    parser.add_argument("-o", "--output", required=True, help="Output file for extracted subtree")
    parser.add_argument("-S1", required=True, help="Starting node ID")
    parser.add_argument("-S2", required=True, help="Ending node ID")
    args = parser.parse_args()

    # Load the tree
    tree = Tree(args.input)

    # Get MRCA of S1 and S2
    try:
        subtree = tree.get_common_ancestor(args.S1, args.S2)
    except:
        print(f"Error: could not find both nodes '{args.S1}' and '{args.S2}' in the tree.")
        return

    # Write subtree to output
    subtree.write(format=1, outfile=args.output)
    print(f"Subtree between '{args.S1}' and '{args.S2}' written to {args.output}")

if __name__ == "__main__":
    main()
