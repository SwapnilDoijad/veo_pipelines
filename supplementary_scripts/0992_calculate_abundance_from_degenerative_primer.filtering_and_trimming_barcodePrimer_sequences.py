# import argparse
# from Bio import SeqIO
# from Bio.Seq import Seq
# from Bio.SeqRecord import SeqRecord

# def read_sequences_from_file(file_path):
#     """Reads a list of sequences from a file."""
#     with open(file_path, 'r') as file:
#         sequences = [line.strip() for line in file if line.strip()]
#     return sequences

# def trim_fasta(input_fasta, output_fasta, start_sequences, end_sequences, length_report):
#     """
#     Trim sequences in a FASTA file, keeping only the region between any of the start and end sequences.
    
#     Parameters:
#     input_fasta (str): The path to the input FASTA file.
#     output_fasta (str): The path to the output FASTA file.
#     start_sequences (list): A list of sequences indicating where to start keeping the sequence.
#     end_sequences (list): A list of sequences indicating where to stop keeping the sequence.
#     length_report (str): The path to the output file for lengths before and after trimming.
    
#     Returns:
#     None
#     """
#     trimmed_sequences = []
#     length_data = []

#     for record in SeqIO.parse(input_fasta, "fasta"):
#         original_sequence = str(record.seq)
#         trimmed_sequence = None
#         for start_sequence in start_sequences:
#             for end_sequence in end_sequences:
#                 trimmed_sequence = trim_sequence_from_sequence(original_sequence, start_sequence, end_sequence)
#                 if trimmed_sequence:
#                     break
#             if trimmed_sequence:
#                 break
#         if trimmed_sequence:
#             trimmed_record = SeqRecord(Seq(trimmed_sequence), id=record.id)
#             trimmed_sequences.append(trimmed_record)
#             length_data.append((record.id, len(original_sequence), len(trimmed_sequence)))

#     # Writing the trimmed sequences to the output fasta file in single line format
#     with open(output_fasta, 'w') as output_handle:
#         for record in trimmed_sequences:
#             output_handle.write(f">{record.id} \n{str(record.seq)}\n")

#     # Writing the length report to the length_report file
#     with open(length_report, 'w') as length_handle:
#         length_handle.write("Header\tLength_Before_Trim\tLength_After_Trim\n")
#         for data in length_data:
#             length_handle.write(f"{data[0]}\t{data[1]}\t{data[2]}\n")

# def trim_sequence_from_sequence(sequence, start_sequence, end_sequence):
#     """
#     Trim the input sequence, keeping only the region between start_sequence and end_sequence.
    
#     Parameters:
#     sequence (str): The input sequence.
#     start_sequence (str): The sequence indicating where to start keeping the sequence.
#     end_sequence (str): The sequence indicating where to stop keeping the sequence.
    
#     Returns:
#     str: The trimmed sequence.
#     """
#     start_index = sequence.find(start_sequence)
#     end_index = sequence.find(end_sequence)
    
#     if start_index != -1 and end_index != -1 and start_index < end_index:
#         return sequence[start_index + len(start_sequence):end_index]
#     return None

# def main():
#     parser = argparse.ArgumentParser(description="Trim sequences in a FASTA file based on given start and end sequences from files.")
#     parser.add_argument('-f', '--input_fasta', required=True, help="Path to the input FASTA file.")
#     parser.add_argument('-o', '--output_fasta', required=True, help="Path to the output FASTA file.")
#     parser.add_argument('-1', '--start_sequences_file', required=True, help="File containing list of start sequences.")
#     parser.add_argument('-2', '--end_sequences_file', required=True, help="File containing list of end sequences.")
#     parser.add_argument('-l', '--length_report', required=True, help="Path to the output file for lengths before and after trimming.")
    
#     args = parser.parse_args()
    
#     start_sequences = read_sequences_from_file(args.start_sequences_file)
#     end_sequences = read_sequences_from_file(args.end_sequences_file)
    
#     trim_fasta(args.input_fasta, args.output_fasta, start_sequences, end_sequences, args.length_report)

# if __name__ == "__main__":
#     main()

import argparse
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

def read_sequences_from_file(file_path):
    """Reads a list of sequences from a file."""
    with open(file_path, 'r') as file:
        sequences = [line.strip() for line in file if line.strip()]
    return sequences

def trim_fastq(input_fastq, output_fastq, start_sequences, end_sequences, length_report):
    """
    Trim sequences in a FASTQ file, keeping only the region between any of the start and end sequences.
    
    Parameters:
    input_fastq (str): The path to the input FASTQ file.
    output_fastq (str): The path to the output FASTQ file.
    start_sequences (list): A list of sequences indicating where to start keeping the sequence.
    end_sequences (list): A list of sequences indicating where to stop keeping the sequence.
    length_report (str): The path to the output file for lengths before and after trimming.
    
    Returns:
    None
    """
    trimmed_sequences = []
    length_data = []

    for record in SeqIO.parse(input_fastq, "fastq"):
        original_sequence = str(record.seq)
        trimmed_sequence = None
        for start_sequence in start_sequences:
            for end_sequence in end_sequences:
                trimmed_sequence = trim_sequence_from_sequence(original_sequence, start_sequence, end_sequence)
                if trimmed_sequence:
                    break
            if trimmed_sequence:
                break
        if trimmed_sequence:
            trimmed_record = SeqRecord(Seq(trimmed_sequence), id=record.id, description=record.description, letter_annotations={"phred_quality": record.letter_annotations["phred_quality"][len(start_sequence):(len(start_sequence)+len(trimmed_sequence))]})
            trimmed_sequences.append(trimmed_record)
            length_data.append((record.id, len(original_sequence), len(trimmed_sequence)))

    # Writing the trimmed sequences to the output fastq file
    with open(output_fastq, 'w') as output_handle:
        SeqIO.write(trimmed_sequences, output_handle, "fastq")

    # Writing the length report to the length_report file
    with open(length_report, 'w') as length_handle:
        length_handle.write("Header\tLength_Before_Trim\tLength_After_Trim\n")
        for data in length_data:
            length_handle.write(f"{data[0]}\t{data[1]}\t{data[2]}\n")

def trim_sequence_from_sequence(sequence, start_sequence, end_sequence):
    """
    Trim the input sequence, keeping only the region between start_sequence and end_sequence.
    
    Parameters:
    sequence (str): The input sequence.
    start_sequence (str): The sequence indicating where to start keeping the sequence.
    end_sequence (str): The sequence indicating where to stop keeping the sequence.
    
    Returns:
    str: The trimmed sequence.
    """
    start_index = sequence.find(start_sequence)
    end_index = sequence.find(end_sequence)
    
    if start_index != -1 and end_index != -1 and start_index < end_index:
        return sequence[start_index + len(start_sequence):end_index]
    return None

def main():
    parser = argparse.ArgumentParser(description="Trim sequences in a FASTQ file based on given start and end sequences from files.")
    parser.add_argument('-f', '--input_fastq', required=True, help="Path to the input FASTQ file.")
    parser.add_argument('-o', '--output_fastq', required=True, help="Path to the output FASTQ file.")
    parser.add_argument('-1', '--start_sequences_file', required=True, help="File containing list of start sequences.")
    parser.add_argument('-2', '--end_sequences_file', required=True, help="File containing list of end sequences.")
    parser.add_argument('-l', '--length_report', required=True, help="Path to the output file for lengths before and after trimming.")
    
    args = parser.parse_args()
    
    start_sequences = read_sequences_from_file(args.start_sequences_file)
    end_sequences = read_sequences_from_file(args.end_sequences_file)
    
    trim_fastq(args.input_fastq, args.output_fastq, start_sequences, end_sequences, args.length_report)

if __name__ == "__main__":
    main()
