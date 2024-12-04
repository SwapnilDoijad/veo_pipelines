import argparse

def reverse_complement(sequence):
    complement_dict = {'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C'}
    reverse_sequence = sequence[::-1]
    reverse_complement_sequence = ''.join([complement_dict[base] for base in reverse_sequence])
    return reverse_complement_sequence

def process_fasta(fasta_string):
    lines = fasta_string.strip().split('\n')
    headers = []
    sequences = []
    
    for line in lines:
        if line.startswith('>'):
            headers.append(line)
        else:
            sequences.append(line)
    
    return headers, sequences

def main():
    parser = argparse.ArgumentParser(description="Reverse complement DNA sequence from a FASTA file")
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
    parser.add_argument("-o", "--output", required=True, help="Output file for reverse complement sequences")
    args = parser.parse_args()

    with open(args.input, "r") as input_file:
        fasta_input = input_file.read()

    headers, sequences = process_fasta(fasta_input)
    rc_sequences = [reverse_complement(sequence) for sequence in sequences]

    with open(args.output, "w") as output_file:
        for header, rc_sequence in zip(headers, rc_sequences):
            output_file.write(header + "\n")
            output_file.write(rc_sequence + "\n")

if __name__ == "__main__":
    main()
