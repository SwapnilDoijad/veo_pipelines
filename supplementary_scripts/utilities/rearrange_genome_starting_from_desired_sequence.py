import argparse
from Bio import SeqIO, pairwise2
from Bio.Seq import Seq

def find_exact_match(genome_seq, query_seq):
    """
    Finds an exact match for the query sequence in the genome.
    
    Args:
    genome_seq (str): The full genome sequence.
    query_seq (str): The sequence to match (start sequence).

    Returns:
    int: The starting index of the exact match, or -1 if not found.
    """
    start_index = genome_seq.find(query_seq)
    if start_index != -1:
        return start_index, "exact match", 0
    return -1, None, None

def find_approximate_match(genome_seq, query_seq, max_mismatches=3):
    """
    Finds the best approximate match for the query sequence in the genome, allowing for mismatches,
    and correctly identifies mismatches while ignoring gaps.
    
    Args:
    genome_seq (str): The full genome sequence.
    query_seq (str): The sequence to match (start sequence).
    max_mismatches (int): Maximum number of allowed mismatches.
    
    Returns:
    tuple: (start_index, match_type, mismatch_count) where:
        - start_index is the starting index of the best match in the genome.
        - match_type is either 'exact match' or 'match with mismatches'.
        - mismatch_count is the number of mismatches if applicable, or 0 for an exact match.
    """
    alignments = pairwise2.align.localms(genome_seq, query_seq, 2, -1, -1, -1)

    for alignment in alignments:
        aligned_genome, aligned_query, score, start, end = alignment

        # Count mismatches but ignore gaps
        mismatches = 0
        for a, b in zip(aligned_genome, aligned_query):
            if a == '-' or b == '-':
                continue
            if a != b:
                mismatches += 1

        # Check if it's an exact match or match with mismatches
        if mismatches == 0:
            return start, "exact match", mismatches
        elif mismatches <= max_mismatches:
            return start, "match with mismatches", mismatches

    return -1, None, None

def rearrange_genome(genome_seq, start_seq, max_mismatches=3):
    """
    Rearranges the genome sequence so that it starts from a specific subsequence (or its reverse complement),
    allowing mismatches. Ensures the final genome is in the 5' to 3' direction of the start sequence.
    
    Args:
    genome_seq (str): The full genome sequence.
    start_seq (str): The sequence to start the genome from.
    max_mismatches (int): Maximum allowed mismatches.

    Returns:
    str: Rearranged genome sequence starting from start_seq in 5' to 3' direction.
    dict: Information about start sequence findings.
    """
    info = {}

    # Step 1: Try to find an exact match for the start_seq
    start_index, start_match_type, start_mismatches = find_exact_match(genome_seq, start_seq)
    
    # Step 2: If no exact match, try to find an exact match for the reverse complement of the start_seq
    reverse_complement = False
    if start_index == -1:
        start_seq_rc = str(Seq(start_seq).reverse_complement())  # Generate reverse complement
        start_index, start_match_type, start_mismatches = find_exact_match(genome_seq, start_seq_rc)
        reverse_complement = True
        
        # If exact match is found for the reverse complement, no need to look for approximate matches
        if start_index != -1:
            info["start_seq"] = f"Found reverse complement of start sequence '{start_seq_rc}' at index {start_index} ({start_match_type}, {start_mismatches} mismatches)"
        else:
            # Step 3: If no exact match for reverse complement, try to find an approximate match for the start_seq
            start_index, start_match_type, start_mismatches = find_approximate_match(genome_seq, start_seq, max_mismatches)
            
            # Step 4: If no approximate match for start_seq, try to find an approximate match for the reverse complement
            if start_index == -1:
                start_index, start_match_type, start_mismatches = find_approximate_match(genome_seq, start_seq_rc, max_mismatches)
                reverse_complement = True
                
                if start_index == -1:
                    info["start_seq"] = f"Neither start sequence '{start_seq}' nor its reverse complement found with up to {max_mismatches} mismatches."
                    raise ValueError(info["start_seq"])
                
                info["start_seq"] = f"Found reverse complement of start sequence '{start_seq_rc}' at index {start_index} ({start_match_type}, {start_mismatches} mismatches)"
            else:
                info["start_seq"] = f"Found start sequence '{start_seq}' at index {start_index} ({start_match_type}, {start_mismatches} mismatches)"
    else:
        # Exact match for the original start sequence
        info["start_seq"] = f"Found start sequence '{start_seq}' at index {start_index} ({start_match_type}, {start_mismatches} mismatches)"

    # Rearrange the genome so that it starts from the start_seq (or reverse complement)
    rearranged_genome = genome_seq[start_index:] + genome_seq[:start_index]

    # If the start sequence was found in reverse complement orientation, reverse and complement the genome
    if reverse_complement:
        rearranged_genome = str(Seq(rearranged_genome).reverse_complement())
        # Adjust the rearrangement so the reverse complement start_seq is at the beginning
        new_start_index = len(rearranged_genome) - len(start_seq)  # Reverse complement starts at the end
        rearranged_genome = rearranged_genome[new_start_index:] + rearranged_genome[:new_start_index]
        info["direction"] = "The genome was reversed and complemented to ensure the output is in 5' to 3' direction, and the reverse complement of the start sequence is at the start."

    return rearranged_genome, info



def format_sequence_in_lines(sequence, line_length=60):
    """
    Formats a sequence into lines of a specified length.

    Args:
    sequence (str): The genome sequence to format.
    line_length (int): Number of characters per line (default is 60).

    Returns:
    str: The formatted sequence with lines of the specified length.
    """
    return "\n".join([sequence[i:i + line_length] for i in range(0, len(sequence), line_length)])

def read_fasta_sequence(file_path):
    """
    Reads the sequence from a FASTA file.

    Args:
    file_path (str): Path to the FASTA file.

    Returns:
    str: The sequence read from the FASTA file.
    """
    with open(file_path, 'r') as fasta_file:
        record = SeqIO.read(fasta_file, "fasta")
        return str(record.seq)

def write_info_file(output_file, info):
    """
    Writes the information about the rearrangement process to a .info file.

    Args:
    output_file (str): The path of the output file.
    info (dict): A dictionary containing information about the start sequence findings.
    """
    info_file = output_file + ".rearrangement_info"
    with open(info_file, 'w') as info_f:
        for key, value in info.items():
            info_f.write(f"{key}: {value}\n")
    print(f"Info written to {info_file}")

def main():
    # Set up the argument parser
    parser = argparse.ArgumentParser(description="Rearrange a genome from a FASTA file starting at a specific sequence or its reverse complement, allowing mismatches.")
    
    # Define the arguments
    parser.add_argument('-i', '--input', required=True, help="Input FASTA file containing the genome sequence.")
    parser.add_argument('-o', '--output', required=True, help="Output file to save the rearranged genome.")
    parser.add_argument('-s', '--start', required=True, help="FASTA file containing the sequence to start the genome from.")
    parser.add_argument('-m', '--mismatches', type=int, default=3, help="Maximum allowed mismatches for approximate matching.")
    
    # Parse the arguments
    args = parser.parse_args()

    # Read genome and start sequences
    genome_record = SeqIO.read(args.input, "fasta")
    genome_sequence = str(genome_record.seq)
    start_sequence = read_fasta_sequence(args.start)

    # Get the FASTA ID from the input file (e.g., MYID from the header >MYID)
    fasta_id = genome_record.id

    try:
        # Rearrange the genome
        rearranged_genome, info = rearrange_genome(genome_sequence, start_sequence, args.mismatches)

        # Format the rearranged genome into lines of 60 characters
        formatted_genome = format_sequence_in_lines(rearranged_genome)

        # Write the rearranged genome to the output file with a new header that includes the FASTA file ID
        with open(args.output, 'w') as output_file:
            output_file.write(f">{fasta_id}_rearranged\n{formatted_genome}\n")
        
        print(f"Rearranged genome written to {args.output}")

        # Write the info file
        write_info_file(args.output, info)

    except ValueError as error_message:
        info = {"Error": str(error_message)}
        # Write the info file even if there's an error
        write_info_file(args.output, info)

if __name__ == "__main__":
    main()
