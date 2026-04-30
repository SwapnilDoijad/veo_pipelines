#!/usr/bin/env python3

import argparse
import os
import re
import networkx as nx
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord


def parse_args():
    parser = argparse.ArgumentParser(
        description="Split Unicycler assembly by component and join contigs with fixed N gaps"
    )
    parser.add_argument(
        "-i", "--input",
        required=True,
        help="Input FASTA (assembly.fasta)"
    )
    parser.add_argument(
        "-g", "--gfa",
        required=True,
        help="Unicycler GFA file (e.g. 14_contigs_placed.gfa)"
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Output prefix (path allowed; basename will be used for FASTA IDs)"
    )
    parser.add_argument(
        "--gap",
        type=int,
        default=10,
        help="Number of Ns between contigs (default: 10)"
    )
    return parser.parse_args()


def main():
    args = parse_args()

    # 🔒 FORCE CLEAN SAMPLE NAME (NO PATHS, EVER)
    sample = os.path.basename(args.output)
    sample = re.sub(r"[^\w.-]", "_", sample)

    gap_seq = "N" * args.gap

    # --- build graph from GFA ---
    G = nx.Graph()
    with open(args.gfa) as gfa:
        for line in gfa:
            if line.startswith("S"):
                _, sid, *_ = line.strip().split("\t")
                G.add_node(sid)
            elif line.startswith("L"):
                _, s1, _, s2, *_ = line.strip().split("\t")
                G.add_edge(s1, s2)

    components = list(nx.connected_components(G))

    # --- load FASTA ---
    records = {r.id: r for r in SeqIO.parse(args.input, "fasta")}

    # --- process each component ---
    for i, comp in enumerate(components, start=1):
        comp_records = [records[c] for c in comp if c in records]
        if not comp_records:
            continue

        # deterministic order: largest contig first
        comp_records.sort(key=lambda r: len(r.seq), reverse=True)

        joined_seq = gap_seq.join(str(r.seq) for r in comp_records)
        member_ids = ",".join(r.id for r in comp_records)

        out_record = SeqRecord(
            Seq(joined_seq),
            id=f"{sample}_component{i}",
            name=f"{sample}_component{i}",
            description=""
        )

        # overwrite description explicitly
        out_record.description = (
            f"{sample}_component{i} "
            f"component={i};"
            f"contigs={len(comp_records)};"
            f"joined_with={args.gap}N;"
            f"members={member_ids}"
        )

        outdir = os.path.dirname(args.output)
        if outdir == "":
            outdir = "."

        outfile = os.path.join(outdir, f"{sample}_{i}.fasta")

        SeqIO.write(out_record, outfile, "fasta")

        print(
            f"Wrote {outfile}: "
            f"{len(comp_records)} contigs, "
            f"{len(joined_seq):,} bp"
        )

    print("\nDone.")
    print("Headers are path-safe and NCBI-compatible.")


if __name__ == "__main__":
    main()
