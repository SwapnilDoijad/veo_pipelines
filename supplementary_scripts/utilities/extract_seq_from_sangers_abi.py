import glob
import sys
from Bio import SeqIO
import argparse
import os

def main():
	parser = argparse.ArgumentParser(description="Convert ABI (.ab1) Sanger file to fasta ")
	parser.add_argument("-i", "--input_file", required=True, help="Input ABI (.ab1) file.")
	parser.add_argument("-o", "--output_file", required=True, help="Output fasta file.")
	args = parser.parse_args()

	if not os.path.isfile(args.input_file):
		print(f"Error: Input file {args.input_file} does not exist.")
		sys.exit(1)

	try:
		record = SeqIO.read(args.input_file, "abi")
		SeqIO.write(record, args.output_file, "fasta")
		print(f"Successfully converted {args.input_file} to {args.output_file}.")
	except Exception as e:
		print(f"Error processing file {args.input_file}: {e}")	

if __name__ == "__main__":		
	main()
