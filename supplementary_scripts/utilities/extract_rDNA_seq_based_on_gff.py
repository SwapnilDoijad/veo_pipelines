import argparse
from Bio import SeqIO

def parse_gff(gff_file):
    features = []
    with open(gff_file, 'r') as f:
        for line in f:
            if line.startswith("#"):
                continue
            cols = line.strip().split("\t")
            if len(cols) < 9:
                continue
            seqid, source, feature_type, start, end, score, strand, phase, attributes = cols
            if feature_type == "rRNA" and "16S" in attributes:
                features.append({
                    'seqid': seqid,
                    'start': int(start),
                    'end': int(end),
                    'strand': strand,
                    'attributes': attributes
                })
    return features

def extract_16S(fasta_file, gff_file, output_file):
    records = SeqIO.to_dict(SeqIO.parse(fasta_file, "fasta"))
    features = parse_gff(gff_file)

    with open(output_file, "w") as out_f:
        for i, feature in enumerate(features):
            seqid = feature['seqid']
            start = feature['start'] - 1  # GFF is 1-based
            end = feature['end']
            strand = feature['strand']
            attributes = feature['attributes']

            if seqid not in records:
                continue

            sequence = records[seqid].seq[start:end]
            if strand == "-":
                sequence = sequence.reverse_complement()

            header = f">{seqid}_16S_{start+1}_{end}_{strand}"
            out_f.write(f"{header}\n{sequence}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract 16S rRNA sequences from FASTA using GFF.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
    parser.add_argument("-g", "--gff", required=True, help="Input GFF file")
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file")

    args = parser.parse_args()
    extract_16S(args.input, args.gff, args.output)
