#!/usr/bin/env python3
"""
Create stacked bar plots from readlength.tsv data
Generates both normal and logarithmic Y-axis versions
Shows read length distribution by sample
"""

import argparse
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from pathlib import Path


def create_plots(input_file, output_folder):
    """
    Create both normal and log scale stacked bar plots
    
    Args:
        input_file: Path to input TSV file
        output_folder: Path to output folder for PNG files
    """
    # Ensure output folder exists
    Path(output_folder).mkdir(parents=True, exist_ok=True)
    
    # Read the data (try tab delimiter first, then whitespace)
    try:
        df = pd.read_csv(input_file, sep='\t')
    except:
        df = pd.read_csv(input_file, sep='\s+', engine='python')
    
    # Extract the categories (ge35, ge50, ge100, ge250)
    # and calculate the ranges for each category
    categories = ['ge35', 'ge50', 'ge100', 'ge250']
    
    # Calculate the read counts in each length range
    # ge35-ge50, ge50-ge100, ge100-ge250, ge250+
    df['range_35_50'] = df['ge35'] - df['ge50']
    df['range_50_100'] = df['ge50'] - df['ge100']
    df['range_100_250'] = df['ge100'] - df['ge250']
    df['range_250_plus'] = df['ge250']
    
    # Get sample names
    samples = df['sample'].values
    
    # Prepare data for stacking
    data_to_plot = df[['range_35_50', 'range_50_100', 'range_100_250', 'range_250_plus']].values
    
    # Setup plotting parameters
    x = np.arange(len(samples))
    width = 0.8
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']
    labels = ['35-50 bp', '50-100 bp', '100-250 bp', '≥250 bp']
    
    # ===== NORMAL SCALE PLOTS =====
    # Plot 1: Stacked bar chart (normal scale, ranges)
    fig, ax = plt.subplots(figsize=(18, 10))
    
    bottom = np.zeros(len(samples))
    for i, (label, color) in enumerate(zip(labels, colors)):
        ax.bar(x, data_to_plot[:, i], width, label=label, bottom=bottom, color=color)
        bottom += data_to_plot[:, i]
    
    ax.set_xlabel('Sample', fontsize=12, fontweight='bold')
    ax.set_ylabel('Number of Reads', fontsize=12, fontweight='bold')
    ax.set_title('Stacked Bar Plot of Read Length Distribution by Sample', fontsize=14, fontweight='bold')
    ax.set_xticks(x)
    ax.set_xticklabels(samples, rotation=90, ha='right', fontsize=9)
    ax.legend(loc='upper right', fontsize=10)
    ax.grid(axis='y', alpha=0.3)
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'{x/1e6:.1f}M' if x >= 1e6 else f'{x/1e3:.0f}K'))
    
    plt.tight_layout()
    output_path_1 = os.path.join(output_folder, 'stacked_barplot.png')
    plt.savefig(output_path_1, dpi=300, bbox_inches='tight')
    print(f"Stacked bar plot saved to: {output_path_1}")
    plt.close()
    
    # Plot 2: Stacked bar chart (normal scale, categories)
    fig2, ax2 = plt.subplots(figsize=(18, 10))
    
    categories_to_plot = ['ge35', 'ge50', 'ge100', 'ge250']
    data_original = df[categories_to_plot].values
    
    bottom2 = np.zeros(len(samples))
    for i, (label, color) in enumerate(zip(categories_to_plot, colors)):
        ax2.bar(x, data_original[:, i], width, label=f'{label} bp', bottom=bottom2, color=color)
        bottom2 += data_original[:, i]
    
    ax2.set_xlabel('Sample', fontsize=12, fontweight='bold')
    ax2.set_ylabel('Number of Reads', fontsize=12, fontweight='bold')
    ax2.set_title('Stacked Bar Plot of Read Length Categories by Sample', fontsize=14, fontweight='bold')
    ax2.set_xticks(x)
    ax2.set_xticklabels(samples, rotation=90, ha='right', fontsize=9)
    ax2.legend(loc='upper right', fontsize=10)
    ax2.grid(axis='y', alpha=0.3)
    ax2.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'{x/1e6:.1f}M' if x >= 1e6 else f'{x/1e3:.0f}K'))
    
    plt.tight_layout()
    output_path_2 = os.path.join(output_folder, 'stacked_barplot_log.png')
    plt.savefig(output_path_2, dpi=300, bbox_inches='tight')
    print(f"Stacked bar plot (log scale) saved to: {output_path_2}")
    plt.close()
    
    # ===== LOG SCALE PLOTS =====
    # Plot 3: Stacked bar chart (log scale, ranges)
    fig3, ax3 = plt.subplots(figsize=(18, 10))
    
    bottom3 = np.zeros(len(samples))
    for i, (label, color) in enumerate(zip(labels, colors)):
        ax3.bar(x, data_to_plot[:, i], width, label=label, bottom=bottom3, color=color)
        bottom3 += data_to_plot[:, i]
    
    ax3.set_xlabel('Sample', fontsize=12, fontweight='bold')
    ax3.set_ylabel('Number of Reads (log scale)', fontsize=12, fontweight='bold')
    ax3.set_title('Stacked Bar Plot of Read Length Distribution by Sample (Log Y-axis)', fontsize=14, fontweight='bold')
    ax3.set_xticks(x)
    ax3.set_xticklabels(samples, rotation=90, ha='right', fontsize=9)
    ax3.legend(loc='upper right', fontsize=10)
    ax3.set_yscale('log')
    ax3.grid(axis='y', alpha=0.3, which='both')
    
    plt.tight_layout()
    output_path_3 = os.path.join(output_folder, 'stacked_barplot_log.png')
    plt.savefig(output_path_3, dpi=300, bbox_inches='tight')
    print(f"Stacked bar plot (log scale) saved to: {output_path_3}")
    plt.close()
    
    print("\nAll plots generated successfully!")


def main():
    parser = argparse.ArgumentParser(
        description='Create stacked bar plots from readlength data (normal and log scale)'
    )
    parser.add_argument('-i', '--input', required=True, help='Input TSV file path')
    parser.add_argument('-o', '--output', required=True, help='Output folder path')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"Error: Input file '{args.input}' not found!")
        exit(1)
    
    create_plots(args.input, args.output)


if __name__ == '__main__':
    main()
