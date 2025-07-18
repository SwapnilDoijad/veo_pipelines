import pandas as pd
import plotly.graph_objects as go
import argparse
import os
import numpy as np

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Combine files, generate rarefaction curves, and identify plateau points.")
parser.add_argument("-d", "--directory", required=True, help="Path to the directory containing input files.")
parser.add_argument("-o", "--output", required=True, help="Path to save the output plot image (PNG or SVG).")
parser.add_argument("-t", "--tsv_output", required=True, help="Path to save the rarefaction TSV output of taxa counts.")
parser.add_argument("--plateau_output", required=True, help="Path to save the plateau information as a text file.")
parser.add_argument("-html", "--html_output", required=True, help="Path to save the interactive HTML plot.")
parser.add_argument("--max_samples", type=int, default=2000, help="Maximum number of reads for rarefaction curve.")
parser.add_argument("--step", type=int, default=100, help="Step size for subsampling (default is 100).")
parser.add_argument("--repeats", type=int, default=10, help="Number of subsampling repetitions for each step.")
args = parser.parse_args()

files = [f for f in os.listdir(args.directory) if f.endswith(".fasta.out")]
file_groups = {}

for filename in files:
    prefix = filename.split(".")[0]
    if prefix not in file_groups:
        file_groups[prefix] = []
    file_groups[prefix].append(filename)

fig = go.Figure()
rarefaction_data = []
plateau_data = []

for prefix, file_list in file_groups.items():
    combined_data = pd.DataFrame()

    for filename in file_list:
        file_path = os.path.join(args.directory, filename)
        try:
            data = pd.read_csv(file_path, sep="\t", header=None)
            combined_data = pd.concat([combined_data, data], ignore_index=True)
        except Exception as e:
            print(f"Error reading {filename}: {e}")
            continue

    combined_data = combined_data.drop_duplicates(subset=[1])
    combined_filename = f"{prefix}.combined.fasta.out"
    combined_path = os.path.join(args.directory, combined_filename)
    combined_data.to_csv(combined_path, sep="\t", index=False, header=False)
    print(f"Saved combined file with deduplication: {combined_filename}")

    taxa_ids = combined_data[2]
    total_reads = len(taxa_ids)
    avg_unique_taxa_counts = []
    sample_sizes = list(range(args.step, min(total_reads, args.max_samples) + 1, args.step))

    if not sample_sizes:
        print(f"No sufficient data for rarefaction in {combined_filename}")
        fig.add_trace(go.Scatter(
            x=[],
            y=[],
            mode='markers',
            name=f"{prefix} (no data)",
            marker=dict(symbol='x', color='red', size=10)
        ))

        rarefaction_data.append({
            "Filename": combined_filename,
            "Sample_Size": "None",
            "Average_Unique_Taxa": "None"
        })
        plateau_data.append({
            "Filename": combined_filename,
            "Total_Reads": total_reads,
            "Plateau_Sample_Size": "None",
            "Plateau_Unique_Taxa": "None",
            "Status": "failed",
            "Plateau_Status": "Insufficient_data_to_calculate_plateau"
        })
        continue

    for size in sample_sizes:
        unique_counts = []
        for _ in range(args.repeats):
            sampled_taxa = taxa_ids.sample(n=size, replace=False).unique()
            unique_counts.append(len(sampled_taxa))
        avg_unique_taxa = np.mean(unique_counts)
        avg_unique_taxa_counts.append(avg_unique_taxa)
        rarefaction_data.append({
            "Filename": combined_filename,
            "Sample_Size": size,
            "Average_Unique_Taxa": avg_unique_taxa
        })

    rate_of_increase = np.diff(avg_unique_taxa_counts)
    plateau_sample_size = None
    plateau_unique_taxa = None
    plateau_status = None
    threshold = 1

    if len(rate_of_increase) > 0:
        for i, rate in enumerate(rate_of_increase):
            if rate < threshold:
                plateau_sample_size = sample_sizes[i + 1]
                plateau_unique_taxa = avg_unique_taxa_counts[i + 1]
                plateau_status = "Plateau_Detected"
                break
        if plateau_sample_size is None:
            plateau_sample_size = sample_sizes[-1]
            plateau_unique_taxa = avg_unique_taxa_counts[-1]
            plateau_status = f"Plateau_NOT_Reached_(last_rate:_{rate_of_increase[-1]:.2f})"
    else:
        plateau_sample_size = "None"
        plateau_unique_taxa = "None"
        plateau_status = "Insufficient_data_to_calculate_plateau"

    status = "pass" if plateau_status == "Plateau_Detected" and total_reads >= plateau_sample_size else "failed"
    status = status.replace(" ", "_")
    plateau_status = plateau_status.replace(" ", "_")

    plateau_data.append({
        "Filename": combined_filename,
        "Total_Reads": total_reads,
        "Plateau_Sample_Size": plateau_sample_size,
        "Plateau_Unique_Taxa": plateau_unique_taxa,
        "Status": status,
        "Plateau_Status": plateau_status
    })

    marker_style = dict(size=5, symbol='circle')
    if status == "failed":
        marker_style = dict(size=8, symbol='x', color='black')

    fig.add_trace(go.Scatter(
        x=sample_sizes,
        y=avg_unique_taxa_counts,
        mode='lines+markers',
        name=prefix,
        line=dict(width=1),
        marker=marker_style
    ))

# Save rarefaction data
rarefaction_df = pd.DataFrame(rarefaction_data)
rarefaction_df.to_csv(args.tsv_output, sep="\t", index=False)
print(f"Saved rarefaction data to {args.tsv_output}")

# Save plateau data
plateau_df = pd.DataFrame(plateau_data)
first_row = plateau_df.iloc[0]
sorted_plateau_df = pd.concat([first_row.to_frame().T, plateau_df.iloc[1:].sort_values(by="Total_Reads", ascending=True)], ignore_index=True)
sorted_plateau_df.to_csv(args.plateau_output, sep="\t", index=False)
print(f"Saved plateau data to {args.plateau_output}")

# Convert column safely to numeric, coercing errors like "None" to NaN
y_values = pd.to_numeric(rarefaction_df['Average_Unique_Taxa'], errors='coerce').dropna()

if len(y_values) > 0:
    max_y = y_values.max() * 1.1
    max_y = max(max_y, 10)  # Ensure it's at least 10 for visual clarity
else:
    max_y = 10


# Finalize plot layout
fig.update_layout(
    title="Rarefaction Curves of Taxa Accumulation",
    xaxis_title="Sample_Size_(Number_of_Reads)",
    yaxis_title="Average_Unique_Taxa_Count",
    yaxis=dict(range=[0, max_y]),
    xaxis=dict(range=[0, args.max_samples]),
)

fig.write_html(args.html_output)
fig.write_image(args.output, width=1600, height=1200, scale=2)
print(f"Plot saved as {args.output} and interactive HTML saved as {args.html_output}")
