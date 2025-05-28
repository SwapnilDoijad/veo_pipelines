import argparse
from Bio import SeqIO
from Bio.Seq import Seq

def detect_and_trim_repeats(sequence, region_length=250, min_overlap=8, is_start=True):
    """
    Detects repeated sequences in the first or last region (based on `is_start`).
    Only considers overlaps longer than `min_overlap`.
    Returns the sequence with repeats removed, the repeat sequence, and its length.
    """
    if is_start:
        region = str(sequence[:region_length])
    else:
        region = str(sequence[-region_length:])

    repeat_seq = ""
    repeat_length = 0

    # Detect repeating sequences
    for i in range(min_overlap, len(region)):
        if is_start:
            # Check if the prefix is repeated
            if region[:i] in region[i:]:
                repeat_seq = region[:i]
                repeat_length = len(repeat_seq)
            else:
                break
        else:
            # Check if the suffix is repeated
            if region[-i:] in region[:-i]:
                repeat_seq = region[-i:]
                repeat_length = len(repeat_seq)
            else:
                break

    # Trim the repeat
    if repeat_length > 0:
        if is_start:
            sequence = sequence[repeat_length:]
        else:
            sequence = sequence[:-repeat_length]

    return sequence, repeat_seq, repeat_length

def detect_and_trim_global_overlap(sequence, min_overlap=8):
    """
    Detect and trim overlaps where the end of the sequence overlaps with the start.
    Only considers overlaps longer than `min_overlap`.
    """
    overlap_length = 0
    sequence_str = str(sequence)

    # Compare the end of the sequence with the start
    for i in range(min_overlap, len(sequence_str) // 2 + 1):
        if sequence_str[:i] == sequence_str[-i:]:
            overlap_length = i

    # Trim the overlapping region from the end
    if overlap_length > 0:
        trimmed_sequence = sequence[:-overlap_length]
        overlap_sequence = sequence_str[:overlap_length]
        return trimmed_sequence, overlap_sequence, overlap_length
    else:
        return sequence, "", 0

def remove_all_repeats(sequence, region_length=250, min_overlap=8):
    """
    Iteratively removes all repeats from the start and end regions,
    and trims overlaps between the end and start of the sequence.
    """
    total_trimmed_start = 0
    total_trimmed_end = 0
    total_trimmed_global = 0
    repeats_info = []

    while True:
        # Detect and trim repeats from the start
        sequence, repeat_seq_start, repeat_len_start = detect_and_trim_repeats(sequence, region_length, min_overlap, is_start=True)
        if repeat_len_start > 0:
            total_trimmed_start += repeat_len_start
            repeats_info.append(f"Start Repeat: {repeat_seq_start} (Length: {repeat_len_start})")
        else:
            repeat_seq_start = None

        # Detect and trim repeats from the end
        sequence, repeat_seq_end, repeat_len_end = detect_and_trim_repeats(sequence, region_length, min_overlap, is_start=False)
        if repeat_len_end > 0:
            total_trimmed_end += repeat_len_end
            repeats_info.append(f"End Repeat: {repeat_seq_end} (Length: {repeat_len_end})")
        else:
            repeat_seq_end = None

        # Detect and trim global overlap between the end and start
        sequence, overlap_seq, overlap_len = detect_and_trim_global_overlap(sequence, min_overlap)
        if overlap_len > 0:
            total_trimmed_global += overlap_len
            repeats_info.append(f"Global Overlap: {overlap_seq} (Length: {overlap_len})")

        # Exit loop if no repeats remain
        if not repeat_seq_start and not repeat_seq_end and overlap_len == 0:
            break

    return sequence, total_trimmed_start, total_trimmed_end, total_trimmed_global, repeats_info

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
            original_length = len(dna_sequence)
            
            # Remove all repeats iteratively
            cleaned_sequence, trimmed_start, trimmed_end, trimmed_global, repeats_info = remove_all_repeats(dna_sequence, 250, min_overlap=8)
            modified_length = len(cleaned_sequence)

            # Create a new record with the modified sequence
            modified_record = record[:modified_length]
            modified_record.seq = cleaned_sequence
            modified_records.append(modified_record)

            # Collect information for the info file
            info_details.append(f"> {record.id}\n")
            info_details.append(f"  Original Length: {original_length}\n")
            for info in repeats_info:
                info_details.append(f"  {info}\n")
            info_details.append(f"  Total Trimmed from Start: {trimmed_start}\n")
            info_details.append(f"  Total Trimmed from End: {trimmed_end}\n")
            info_details.append(f"  Total Trimmed Global Overlap: {trimmed_global}\n")
            info_details.append(f"  Modified Length: {modified_length}\n")

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
    parser = argparse.ArgumentParser(description="Remove all repeats from start, end, and overlapping regions of a DNA sequence.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file containing the DNA sequence.")
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file for the modified DNA sequence.")
    args = parser.parse_args()
    
    main(args.input, args.output)
