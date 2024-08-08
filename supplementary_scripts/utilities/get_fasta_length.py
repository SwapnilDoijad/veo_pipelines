# import argparse

# def fasta_length(file_path):
#     sequence_lengths = {}
#     current_sequence = ""

#     with open(file_path, 'r') as file:
#         for line in file:
#             line = line.strip()
#             if line.startswith(">"):
#                 if current_sequence:
#                     sequence_lengths[header] = len(current_sequence)
#                     current_sequence = ""
#                 header = line[1:]
#             else:
#                 current_sequence += line

#     if current_sequence:
#         sequence_lengths[header] = len(current_sequence)

#     return sequence_lengths

# def main():
#     parser = argparse.ArgumentParser(description='Calculate the length of sequences in a FASTA file.')
#     parser.add_argument('-i', '--input', help='Input FASTA file', required=True)
#     args = parser.parse_args()

#     file_path = args.input
#     lengths = fasta_length(file_path)

#     for header, length in lengths.items():
#         header = header.replace(" ", "_")
#         print(f"{header}\t{length}")

# if __name__ == "__main__":
#     main()

import argparse

def fasta_length(file_path):
    sequence_lengths = {}
    current_sequence = ""
    header = None

    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if line.startswith(">"):
                if current_sequence and header is not None:
                    sequence_lengths[header] = len(current_sequence)
                header = line[1:]  # Capture the entire header line
                current_sequence = ""
            else:
                current_sequence += line

    if current_sequence and header is not None:
        sequence_lengths[header] = len(current_sequence)

    return sequence_lengths

def main():
    parser = argparse.ArgumentParser(description='Calculate the length of sequences in a FASTA file.')
    parser.add_argument('-i', '--input', help='Input FASTA file', required=True)
    args = parser.parse_args()

    file_path = args.input
    lengths = fasta_length(file_path)

    for header, length in lengths.items():
        header = header.replace(" ", "_")  # Replace spaces in headers with underscores for consistency
        print(f"{header}\t{length}")

if __name__ == "__main__":
    main()
