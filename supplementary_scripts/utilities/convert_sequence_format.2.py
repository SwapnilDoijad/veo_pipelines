#usage: python convert_sequence_format.py
#change the format accordingly http://biopython.org/wiki/AlignIO

from Bio import AlignIO

input_handle = open("results/32_veriscan2/tmp/my_alignment.aln.fas", "r")
output_handle = open("results/32_veriscan2/tmp/my_alignment.maf", "w")

alignments = AlignIO.parse(input_handle, "fasta")
AlignIO.write(alignments, output_handle, "maf")

output_handle.close()
input_handle.close()
