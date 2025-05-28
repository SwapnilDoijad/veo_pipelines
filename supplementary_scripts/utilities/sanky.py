

# source	target	value
# by_nanopore_machine	basecalled_by_guppy_(100%)	1996714
# basecalled_by_guppy_(100%)	failed_(20%)	396458
# basecalled_by_guppy_(100%)	passed_(80%)	1600256
# passed_(80%)	not_binned_(4%)	87169
# passed_(80%)	binned_(76%)	1513087
# binned_(76%)	QC10_(30%)	595876
# binned_(76%)	QC<10_(46%)	917211
# QC10_(30%)	to_assembly_(30%)	595876

import pandas as pd
import plotly.graph_objects as go
import argparse
import os

# Argument parser for command-line input
parser = argparse.ArgumentParser(description="Generate a Sankey Diagram from a TSV file.")
parser.add_argument("-i", "--input", required=True, help="Input TSV file path")
args = parser.parse_args()

# Read input file
input_file = args.input
df = pd.read_csv(input_file, sep="\t")

# Extract base filename (without extension) for output file naming
base_filename = os.path.splitext(input_file)[0]
output_html = f"{base_filename}.html"
output_png = f"{base_filename}.png"

# Get unique node names
node_labels = list(set(df["source"]).union(set(df["target"])))
node_mapping = {label: i for i, label in enumerate(node_labels)}

# Convert source and target names to index numbers
df["source_index"] = df["source"].map(node_mapping)
df["target_index"] = df["target"].map(node_mapping)

# Format labels (without percentages)
wrapped_labels = [label.replace('_', '<br>') for label in node_labels]

# Define x positions for better layout
x_positions = {}  
for label in node_labels:
    if label in df["source"].values and label not in df["target"].values:
        x_positions[label] = 0  # Sources (left)
    elif label in df["target"].values and label in df["source"].values:
        x_positions[label] = 0.5  # Intermediate (middle)
    else:
        x_positions[label] = 1  # Final output (right)

# Spread y-positions dynamically to avoid overlap
y_positions = {label: i / len(node_labels) for i, label in enumerate(node_labels)}

# Create Sankey diagram (without font in node)
fig = go.Figure(go.Sankey(
    node=dict(
        pad=80,  # More spacing between nodes
        thickness=40,  # Make nodes thicker
        line=dict(color="black", width=0.5),
        label=wrapped_labels,
        x=[x_positions[label] for label in node_labels],
        y=[y_positions[label] for label in node_labels]
    ),
    link=dict(
        source=df["source_index"],
        target=df["target_index"],
        value=df["value"]
    )
))

# Set font size in layout instead of node
fig.update_layout(
    title_text="Flow Diagram (Optimized Layout, Larger Labels)",
    font=dict(size=22),  # ✅ Set font size globally in layout
    width=1400,
    height=1200
)

# Save output files
fig.write_html(output_html)
fig.write_image(output_png)

print(f"Saved: {output_html}")
print(f"Saved: {output_png}")
