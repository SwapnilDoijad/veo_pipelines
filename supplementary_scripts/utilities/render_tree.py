import argparse
from ete3 import Tree, TreeStyle, TextFace

# Parse arguments
parser = argparse.ArgumentParser(description="Render a Newick tree to a PDF with auto-sizing.")
parser.add_argument("-i", "--input", required=True, help="Input .nwk file")
parser.add_argument("-o", "--output", required=True, help="Output PDF file")
args = parser.parse_args()

# Load tree
tree = Tree(args.input)

# Count tips
num_tips = len(tree)

# Font size based on tip count
def get_font_size(n):
    if n < 20:
        return 14
    elif n < 100:
        return 10
    elif n < 500:
        return 8
    else:
        return 6

font_size = get_font_size(num_tips)

# Add font size to tip labels
for node in tree.iter_leaves():
    face = TextFace(node.name, fsize=font_size)
    node.add_face(face, column=0, position="branch-right")

# Tree style
ts = TreeStyle()
ts.show_leaf_name = False
ts.scale = 120

# Dynamic dimensions based on tree size
width_mm = max(100, num_tips * 10)  # Adjust width dynamically
height_mm = max(100, num_tips * 5)  # Adjust height dynamically

# Render tree to PDF with dynamic dimensions
tree.render(args.output, w=width_mm, h=height_mm, units="mm", tree_style=ts)
