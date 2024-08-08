import argparse
from Bio import SeqIO
from Bio.Seq import Seq
import os

def compute_lps_array(seq):
    """
    Compute the longest prefix suffix (LPS) array used in the KMP algorithm.
    """
    lps = [0] * len(seq)
    length = 0
    i = 1

    while i < len(seq):
        if seq[i] == seq[length]:
            length += 1
            lps[i] = length
            i += 1
        else:
            if length != 0:
                length = lps[length - 1]
            else:
                lps[i] = 0
                i += 1
    return lps

def find_longest_prefix_suffix(seq):
    """
    Find the longest prefix which is also a suffix.
    """
    lps = compute_lps_array(seq)
    return lps[-1]

def main(input_file, output_file):
    try:
        # Derive the info file name from the output file name
        info_file = output_file + ".info"
        
        # Read all DNA sequences from the input FASTA file
        with open(input_file, "r") as infile:
            records = list(SeqIO.parse(infile, "fasta"))

        # Create a list to store modified records
        modified_records = []
        info_details = []

        for record in records:
            dna_sequence = record.seq
            dna_sequence_str = str(dna_sequence)

            # Find the longest prefix which is also a suffix
            overlap_len = find_longest_prefix_suffix(dna_sequence_str)
            overlap_seq = dna_sequence_str[:overlap_len]

            # Length before trimming
            length_before = len(dna_sequence)

            # If overlap is found and it is more than 5 bases, remove it from the 3'-end
            if overlap_len > 5:
                modified_dna_sequence = dna_sequence[:-overlap_len]
                # Length after trimming
                length_after = len(modified_dna_sequence)
                # Create a new record with the modified sequence
                modified_record = record[:len(modified_dna_sequence)]
                modified_record.seq = modified_dna_sequence
                modified_records.append(modified_record)
                # Collect information for the info file
                info_details.append(f"> {record.id}\n")
                info_details.append(f"  Original Length: {length_before}\n")
                info_details.append(f"  Overlap Length: {overlap_len}\n")
                info_details.append(f"  Modified Length: {length_after}\n")
                info_details.append(f"  Overlap Sequence: {overlap_seq}\n")
            else:
                # No trimming done, keep the original record
                modified_records.append(record)

        # Write the modified DNA sequences to the output FASTA file
        with open(output_file, "w") as outfile:
            SeqIO.write(modified_records, outfile, "fasta")

        # Write the overlap information to the info file, if any
        if info_details:
            with open(info_file, "w") as infofile:
                infofile.writelines(info_details)
    
    except FileNotFoundError:
        print(f"Error: The file {input_file} was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Remove overlapping sequence from the 3'-end of a DNA sequence.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file containing the DNA sequence.")
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file for the modified DNA sequence.")
    args = parser.parse_args()
    
    main(args.input, args.output)
