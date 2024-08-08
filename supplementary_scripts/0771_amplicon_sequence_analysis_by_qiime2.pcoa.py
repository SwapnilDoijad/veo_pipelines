import argparse
import pandas as pd
import numpy as np
from sklearn.manifold import MDS
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

def main(matrix_file, metadata_file, output_file):
    # Step 1: Read the distance matrix from the file
    distance_matrix = pd.read_csv(matrix_file, sep='\t', header=0, index_col=0).to_numpy()

    # Step 2: Read the metadata file
    metadata = np.genfromtxt(metadata_file, delimiter='\t', dtype=str, skip_header=1)

    # Extract treatment labels and organ information from metadata
    treatments = {row[0]: row[1] for row in metadata}
    organs = {row[0]: row[2] for row in metadata}

    # Sample IDs
    sample_ids = np.genfromtxt(matrix_file, delimiter='\t', dtype=str, usecols=0, skip_header=1)

    # Step 3: Perform PCoA
    mds = MDS(n_components=2, dissimilarity='precomputed', random_state=42)
    pcoa_data = mds.fit_transform(distance_matrix)

    # Step 4: Plot the PCoA with colored labels based on treatment and different shapes based on organs
    plt.figure(figsize=(8, 6))
    legend_handles = {}  # Dictionary to store legend handles for treatments
    organ_legend_handles = {}  # Dictionary to store legend handles for organs
    for sample_id, pcoa_point in zip(sample_ids, pcoa_data):
        treatment = treatments.get(sample_id, 'Unknown')
        organ = organs.get(sample_id, 'Unknown')
        color = 'b' if treatment == 'sham' else 'r' if treatment == 'PCI' else 'g'  # Assign color based on treatment
        shape = 'v' if organ == 'pec' else 's' if organ == 'liver' else '^' if organ == 'spleen' else 'd'  # Assign shape based on organ
        plt.scatter(pcoa_point[0], pcoa_point[1], c=color, marker=shape, s=50, label=None)

        # Add legend handles for treatments if not added already
        if treatment not in legend_handles:
            legend_handles[treatment] = Line2D([0], [0], marker='o', color='w', label=treatment, markerfacecolor=color, markersize=10)

        # Add legend handles for organs if not added already
        if organ not in organ_legend_handles:
            organ_legend_handles[organ] = Line2D([0], [0], marker=shape, color='w', label=organ, markerfacecolor='black', markersize=10)

        # Add labels for each point on the right side
        plt.text(pcoa_point[0] + 0.02, pcoa_point[1], sample_id, fontsize=8, ha='left', va='center')

    plt.xlabel('PCoA 1')  # Label for x-axis
    plt.ylabel('PCoA 2')  # Label for y-axis
    plt.title('PCoA Plot - Treatment (colour) and Organ (shape)')  # Title of the plot
    plt.grid(True)  # Enable grid lines
    plt.subplots_adjust(right=0.8) # Shift the plot to the left to create more space for the legend
    plt.legend(handles=list(legend_handles.values()) + list(organ_legend_handles.values()), bbox_to_anchor=(1.01, 1), loc='upper left')
    

    plt.savefig(output_file)  # Save the plot before showing it
    plt.show()  # Display the plot

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate PCoA plot with treatment and organ")
    parser.add_argument("--matrix_file", type=str, help="Path to the distance matrix file")
    parser.add_argument("--metadata_file", type=str, help="Path to the metadata file")
    parser.add_argument("--output", type=str, help="Path to save the output plot")
    args = parser.parse_args()

    main(args.matrix_file, args.metadata_file, args.output)
