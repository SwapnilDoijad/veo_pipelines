import argparse
from Bio import SeqIO
from BCBio import GFF

## needed source /home/groups/VEO/tools/biopython/myenv/bin/activate

# Function to convert GenBank to GFF3 and FASTA
def convert_genbank(input_file, gff_output_file, fasta_output_file):
    # Convert GenBank to GFF3
    with open(input_file, "r") as input_handle, open(gff_output_file, "w") as gff_output_handle:
        sequences = SeqIO.parse(input_handle, "genbank")
        GFF.write(sequences, gff_output_handle)

    # Convert GenBank to FASTA
    with open(fasta_output_file, "w") as fasta_output_handle:
        for record in SeqIO.parse(input_file, "genbank"):
            SeqIO.write(record, fasta_output_handle, "fasta")

    print(f"Conversion to GFF3 ({gff_output_file}) and FASTA ({fasta_output_file}) completed!")

# Main function to handle argparse
def main():
    parser = argparse.ArgumentParser(description="Convert GenBank file to GFF3 and FASTA formats.")
    
    # Define arguments
    parser.add_argument("-i", "--input", required=True, help="Input GenBank file")
    parser.add_argument("-g", "--gff_output", required=True, help="Output GFF3 file")
    parser.add_argument("-f", "--fasta_output", required=True, help="Output FASTA file")
    
    # Parse arguments
    args = parser.parse_args()

    # Call the conversion function
    convert_genbank(args.input, args.gff_output, args.fasta_output)

# Run the main function
if __name__ == "__main__":
    main()
