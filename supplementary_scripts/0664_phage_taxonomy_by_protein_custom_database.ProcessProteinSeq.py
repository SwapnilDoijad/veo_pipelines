import os
import glob
import gzip
import argparse

# Function to concatenate all protein FASTA files into a single file
def concatenate_fasta_files(proteins_dir, output_fasta):
    with open(output_fasta, 'w') as outfile:
        for file_path in glob.glob(os.path.join(proteins_dir, '**/*.faa.gz'), recursive=True):
            with gzip.open(file_path, 'rt') as infile:  # Decompress on the fly
                outfile.write(infile.read())
    print(f"Concatenated all proteins into {output_fasta}")

# Function to create the virus.accession2taxid file - separated from above as it might change
def create_accession2taxid(proteins_dir, output_tsv):
    with open(output_tsv, 'w') as outfile:
        for file_path in glob.glob(os.path.join(proteins_dir, '**/*.faa.gz'), recursive=True):
            taxid = os.path.basename(os.path.dirname(file_path))
            with gzip.open(file_path, 'rt') as infile:  # Decompress on the fly
                for line in infile:
                    if line.startswith('>'):  # Find FASTA header lines
                        accession = line.split()[0][1:]  # Extract accession (remove '>' and get until first space)
                        outfile.write(f"{accession}\t{taxid}\n")
    print(f"Created virus.accession2taxid file at {output_tsv}")

def main():
    parser = argparse.ArgumentParser(description="Process protein FASTA files and create supplementary files.")
    parser.add_argument('--proteins_dir', required=True, help="Directory containing protein FASTA files (.faa.gz)")
    parser.add_argument('--output_fasta', required=True, help="Path to the output concatenated FASTA file")
    parser.add_argument('--output_tsv', required=True, help="Path to the output virus.accession2taxid TSV file")
    
    args = parser.parse_args()
    
    # Concatenate all protein FASTA files into a single FASTA file
    concatenate_fasta_files(args.proteins_dir, args.output_fasta)
    
    # Create the virus.accession2taxid TSV file
    create_accession2taxid(args.proteins_dir, args.output_tsv)

if __name__ == "__main__":
    main()