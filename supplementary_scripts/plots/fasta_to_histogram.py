import matplotlib.pyplot as plt
from Bio import SeqIO
import argparse
import os

def plot_contig_length_histogram(fasta_file, output_file=None, min_length=None, max_length=None):
    """
    Reads a FASTA file, calculates contig lengths, and plots a histogram.
    
    :param fasta_file: Path to the input FASTA file
    :param output_file: Path to save the histogram image (optional)
    :param min_length: Minimum length of contigs to include (optional)
    :param max_length: Maximum length of contigs to include (optional)
    """
    # Parse the FASTA file and calculate contig lengths
    contig_lengths = [
        len(record.seq) for record in SeqIO.parse(fasta_file, "fasta")
        if (min_length is None or len(record.seq) >= min_length) and
           (max_length is None or len(record.seq) <= max_length)
    ]

    if not contig_lengths:
        print("No contigs found in the FASTA file with the specified length criteria.")
        return

    # Adjust the output file name if min_length or max_length is specified
    if output_file:
        base, ext = os.path.splitext(output_file)
        if min_length is not None:
            base += f".min{min_length}"
        if max_length is not None:
            base += f".max{max_length}"
        output_file = base + ext

    # Plot the histogram
    plt.figure(figsize=(10, 6))
    plt.hist(contig_lengths, bins=30, color='skyblue', edgecolor='black')
    plt.title("Contig Length Distribution")
    plt.xlabel("Contig Length")
    plt.ylabel("Frequency")
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()

    if output_file:
        # Save the histogram to a file
        plt.savefig(output_file)
        print(f"Histogram saved to {output_file}")
    else:
        # Show the histogram
        plt.show()

if __name__ == "__main__":
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Generate a histogram of contig lengths from a FASTA file.")
    parser.add_argument("-i", "--input", required=True, help="Path to the input FASTA file.")
    parser.add_argument("-o", "--output", help="Path to save the output histogram image (optional).")
    parser.add_argument("--min-length", type=int, help="Minimum length of contigs to include (optional).")
    parser.add_argument("--max-length", type=int, help="Maximum length of contigs to include (optional).")

    args = parser.parse_args()

    # Call the function with the provided arguments
    plot_contig_length_histogram(args.input, args.output, args.min_length, args.max_length)