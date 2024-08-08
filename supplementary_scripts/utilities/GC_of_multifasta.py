import argparse
from Bio import SeqIO

def calculate_gc(sequence):
    gc_count = sequence.count('G') + sequence.count('C')
    return (gc_count / len(sequence)) * 100

def main(input_fasta, output_txt):
    gc_contents = {}
    with open(input_fasta, "r") as f:
        for record in SeqIO.parse(f, "fasta"):
            gc_contents[record.id] = calculate_gc(record.seq)
    
    with open(output_txt, "w") as f_out:
        for seq_id, gc_content in gc_contents.items():
            f_out.write(f"{seq_id} {gc_content:.2f}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate GC content of sequences in a multi-FASTA file")
    parser.add_argument("-i", "--input", type=str, required=True, help="Input multi-FASTA file path")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output text file path")
    args = parser.parse_args()
    
    main(args.input, args.output)
