#!/usr/bin/env python3

import argparse

parser = argparse.ArgumentParser(
    description="Select the longest sequence as representative for each cluster."
)

parser.add_argument(
    "-i", "--input",
    required=True,
    help="Input FASTA file"
)

parser.add_argument(
    "-c", "--clusters",
    required=True,
    help="Cluster assignment file (object<TAB>cluster)"
)

parser.add_argument(
    "-o", "--output",
    required=True,
    help="Output FASTA file containing cluster representatives"
)

args = parser.parse_args()

# Read cluster assignments
seq2cluster = {}
with open(args.clusters) as f:
    header = next(f).strip().split("\t")

    for line in f:
        if not line.strip():
            continue

        seqid, cluster = line.rstrip().split("\t")[:2]
        seq2cluster[seqid] = cluster

# Read FASTA
seqs = {}

with open(args.input) as f:
    seqid = None
    seq = []

    for line in f:
        line = line.rstrip()

        if line.startswith(">"):
            if seqid is not None:
                seqs[seqid] = "".join(seq)

            seqid = line[1:].split()[0]
            seq = []
        else:
            seq.append(line)

    if seqid is not None:
        seqs[seqid] = "".join(seq)

# Find longest sequence per cluster
best = {}

for seqid, cluster in seq2cluster.items():

    if seqid not in seqs:
        print(f"WARNING: {seqid} not found in FASTA")
        continue

    length = len(seqs[seqid])

    if cluster not in best or length > best[cluster]["length"]:
        best[cluster] = {
            "seqid": seqid,
            "length": length
        }

# ID output file
ids_file = args.output + ".ids"

# Write representatives
with open(args.output, "w") as out, open(ids_file, "w") as ids_out:

    for cluster in sorted(best, key=lambda x: int(x)):

        seqid = best[cluster]["seqid"]

        out.write(f">{seqid}\n")
        out.write(f"{seqs[seqid]}\n")

        ids_out.write(f"{seqid}\n")

print(f"Clusters processed      : {len(set(seq2cluster.values()))}")
print(f"Representatives written : {len(best)}")
print(f"Output FASTA            : {args.output}")
print(f"Representative IDs      : {ids_file}")