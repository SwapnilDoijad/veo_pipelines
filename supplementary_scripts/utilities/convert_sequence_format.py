#usage: python convert_sequence_format.py
#change the format accordingly /home/groups/VEO/tools/suppl_scripts/convert_sequence_format.py

from Bio import AlignIO

input_handle = open("results/32_veriscan/tmp/my_alignment.aln.fas", "r")
output_handle = open("results/32_veriscan/tmp/my_alignment.maf", "w")

alignments = AlignIO.parse(input_handle, "fasta")
AlignIO.write(alignments, output_handle, "maf")

output_handle.close()
input_handle.close()
