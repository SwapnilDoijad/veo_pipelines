import argparse
from Bio import SeqIO
from BCBio import GFF

def gbk_to_gff(input_file, output_file):
    try:
        with open(input_file, "r") as in_handle, open(output_file, "w") as out_handle:
            records = SeqIO.parse(in_handle, "genbank")
            GFF.write(records, out_handle, include_fasta=True)
        print(f"Conversion successful (with sequences): {output_file}")
    except Exception as e:
        print(f"Error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Convert GBK (GenBank) to GFF3 format with sequence.")
    parser.add_argument("-i", "--input", required=True, help="Input GBK file")
    parser.add_argument("-o", "--output", required=True, help="Output GFF3 file")
    args = parser.parse_args()

    gbk_to_gff(args.input, args.output)

if __name__ == "__main__":
    main()
