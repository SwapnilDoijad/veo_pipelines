import argparse
from Bio import SeqIO
from BCBio import GFF

# Function to clean sequence IDs for consistency
def clean_sequence_ids(record):
    """
    Standardizes sequence IDs to use only the primary ID.
    This function handles various header formats by extracting the first word
    (before any space or special character).
    """
    record.id = record.id.split()[0]  # Extract the primary ID (first word)
    record.name = record.id  # Update the name to match
    record.description = ""  # Remove the description to avoid conflicts
    return record

# Function to convert GenBank to GFF3 and FASTA
def convert_genbank(input_file, gff_output_file, fasta_output_file):
    # Convert GenBank to GFF3
    with open(input_file, "r") as input_handle, open(gff_output_file, "w") as gff_output_handle:
        sequences = (clean_sequence_ids(record) for record in SeqIO.parse(input_handle, "genbank"))
        GFF.write(sequences, gff_output_handle)

    # Convert GenBank to FASTA
    with open(input_file, "r") as input_handle, open(fasta_output_file, "w") as fasta_output_handle:
        for record in SeqIO.parse(input_handle, "genbank"):
            clean_record = clean_sequence_ids(record)
            SeqIO.write(clean_record, fasta_output_handle, "fasta")

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
