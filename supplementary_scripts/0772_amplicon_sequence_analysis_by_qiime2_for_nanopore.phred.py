import os
from Bio import SeqIO

input_fasta = "merged_sequences.fasta"
output_fastq = "sequences.fastq"

with open(input_fasta, "r") as fasta_file, open(output_fastq, "w") as fastq_file:
    for record in SeqIO.parse(fasta_file, "fasta"):
        # Creating a mock quality score of 40 for each base
        record.letter_annotations["phred_quality"] = [40] * len(record.seq)
        SeqIO.write(record, fastq_file, "fastq")
