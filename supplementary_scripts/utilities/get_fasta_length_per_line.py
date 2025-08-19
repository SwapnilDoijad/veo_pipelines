#!/usr/bin/env python3
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <fasta_file>")
    sys.exit(1)

fasta_file = sys.argv[1]

with open(fasta_file) as f:
    seq_id = None
    seq = []
    for line in f:
        line = line.strip()
        if line.startswith(">"):
            if seq_id is not None:
                print(seq_id, len("".join(seq)))
            seq_id = line[1:].split()[0]  # take first word after ">"
            seq = []
        else:
            seq.append(line)
    # print last record
    if seq_id is not None:
        print(seq_id, len("".join(seq)))
