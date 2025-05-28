import pandas as pd
import plotly.graph_objects as go
import argparse
import os
import numpy as np

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Generate rarefaction curves for *.fastq.fasta.out files.")
parser.add_argument("-d", "--directory", required=True, help="Path to the directory containing input files.")
parser.add_argument("-o", "--output", required=True, help="Path to save the output plot image (PNG or SVG).")
parser.add_argument("-t", "--tsv_output", required=True, help="Path to save the rarefaction TSV output.")
parser.add_argument("--plateau_output", required=True, help="Path to save the plateau information as a text file.")
parser.add_argument("-html", "--html_output", required=True, help="Path to save the interactive HTML plot.")
parser.add_argument("--max_samples", type=int, default=2000, help="Maximum number of reads for rarefaction.")
parser.add_argument("--step", type=int, default=100, help="Step size for subsampling.")
args = parser.parse_args()

# List only files ending with "*.fastq.fasta.out"
files = [f for f in os.listdir(args.directory) if f.endswith(".fastq.fasta.out")]

# Initialize Plotly figure and rarefaction data structure
fig = go.Figure()
rarefaction_data = []
plateau_data = []

# Process each file separately
for filename in files:
    file_path = os.path.join(args.directory, filename)
    
    try:
        # Load data
        data = pd.read_csv(file_path, sep="\t", header=None)
    except Exception as e:
        print(f"Error reading {filename}: {e}")
        continue

    # Remove duplicate reads based on the second column (read ID)
    data = data.drop_duplicates(subset=[1])  # Column 1 is the second column (0-indexed)
    
    # Extract taxonomy identifiers from the third column
    taxa_ids = data[2]

    # Calculate total reads after deduplication
    total_reads = len(taxa_ids)

    # Prepare to store unique taxa count
    total_unique_taxa_observed = []
    new_unique_taxa = []
    sample_sizes = list(range(args.step, min(total_reads, args.max_samples) + 1, args.step))

    # Skip if insufficient data
    if not sample_sizes:
        continue
    
    observed_taxa = set()
    plateau_sample_size = None
    plateau_detected = False
    consecutive_low_counts = 0  # Counter for consecutive low increases
    threshold_taxa = 1  # Threshold for defining plateau
    min_consecutive_steps = 3  # How many consecutive low values to define plateau

    # Perform rarefaction sampling
    for size in sample_sizes:
        sampled_taxa = set(taxa_ids.sample(n=size, replace=False))  # Unique taxa found in this sample
        new_taxa = sampled_taxa - observed_taxa  # Taxa newly observed at this step
        observed_taxa.update(sampled_taxa)  # Update observed taxa list
        
        total_unique_taxa_observed.append(len(observed_taxa))
        new_unique_taxa.append(len(new_taxa))
        
        rarefaction_data.append({
            "Filename": filename,
            "Sample_Size": size,
            "Total_Unique_Taxa_Observed": len(observed_taxa),  # Exact cumulative count at each step
            "New_Unique_Taxa": len(new_taxa)  # Exact new taxa found at this step
        })

        # Check for plateau condition
        if len(new_taxa) <= threshold_taxa:
            consecutive_low_counts += 1
        else:
            consecutive_low_counts = 0  # Reset counter if a significant increase happens
        
        if consecutive_low_counts >= min_consecutive_steps and not plateau_detected:
            plateau_sample_size = size  # Record first plateau detection point
            plateau_detected = True

    # Store plateau information
    plateau_data.append({
        "Filename": filename,
        "Total_Reads": total_reads,
        "Plateau_Sample_Size": plateau_sample_size if plateau_detected else "Not Reached",
        "Plateau_Status": "Detected" if plateau_detected else "Not Detected"
    })

    # Plot rarefaction curve
    fig.add_trace(go.Scatter(
        x=sample_sizes,
        y=total_unique_taxa_observed,
        mode='lines+markers',
        name=filename,
        line=dict(width=1)
    ))

# Save rarefaction data with new columns
rarefaction_df = pd.DataFrame(rarefaction_data)
rarefaction_df.to_csv(args.tsv_output, sep="\t", index=False)
print(f"Saved rarefaction data to {args.tsv_output}")

# Save plateau data
plateau_df = pd.DataFrame(plateau_data)
plateau_df.to_csv(args.plateau_output, sep="\t", index=False)
print(f"Saved plateau data to {args.plateau_output}")

# Customize Plotly layout
fig.update_layout(
    title="Rarefaction Curves of Taxa Accumulation",
    xaxis_title="Sample Size (Number of Reads)",
    yaxis_title="Total Unique Taxa Observed",
    yaxis=dict(showgrid=True),
    xaxis=dict(showgrid=True),
    legend_title="Files",
    template="plotly_white"
)

# Save plots
fig.write_html(args.html_output)
fig.write_image(args.output, width=1600, height=1200, scale=2)
print(f"Plot saved as {args.output} and interactive HTML saved as {args.html_output}")