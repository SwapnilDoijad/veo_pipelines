import argparse
from Bio import SeqIO
from Bio.Seq import Seq

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
        info_file = output_file + ".overlap_info"
        
        # Read all DNA sequences from the input FASTA file
        with open(input_file, "r") as infile:
            records = list(SeqIO.parse(infile, "fasta"))

        # Create a list to store modified records
        modified_records = []
        info_details = []

        for record in records:
            dna_sequence = record.seq
            dna_sequence_str = str(dna_sequence)
            original_length = len(dna_sequence)
            total_trimmed = 0

            # Iterate until no overlap is found
            while True:
                # Find the longest prefix which is also a suffix
                overlap_len = find_longest_prefix_suffix(dna_sequence_str)

                # If no significant overlap is found, break the loop
                if overlap_len <= 5:
                    break

                # Trim the overlap from the 3'-end
                dna_sequence_str = dna_sequence_str[:-overlap_len]
                total_trimmed += overlap_len

            # Create a new record with the modified sequence
            modified_sequence = Seq(dna_sequence_str)
            modified_record = record[:len(modified_sequence)]
            modified_record.seq = modified_sequence
            modified_records.append(modified_record)

            # Collect information for the info file
            info_details.append(f"> {record.id}\n")
            info_details.append(f"  Original Length: {original_length}\n")
            info_details.append(f"  Total Trimmed: {total_trimmed}\n")
            info_details.append(f"  Modified Length: {len(modified_sequence)}\n")

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
    parser = argparse.ArgumentParser(description="Iteratively remove overlapping sequence from the 3'-end of a DNA sequence.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file containing the DNA sequence.")
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file for the modified DNA sequence.")
    args = parser.parse_args()
    
    main(args.input, args.output)
