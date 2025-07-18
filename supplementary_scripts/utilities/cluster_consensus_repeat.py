import argparse
import pandas as pd
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from collections import defaultdict
import networkx as nx
from Levenshtein import distance

def parse_args():
    parser = argparse.ArgumentParser(description="Cluster CRISPR repeats with edit distance ≤1")
    parser.add_argument("-i", "--input", required=True, help="Input TSV file")
    parser.add_argument("-o1", "--output_fasta", required=True, help="Output FASTA file")
    parser.add_argument("-o2", "--output_clusters", required=True, help="Output cluster assignments (TSV)")
    return parser.parse_args()

def load_and_write_fasta(input_path, output_fasta):
    df = pd.read_csv(input_path, sep="\t")
    df = df[df["Consensus_Repeat"].notna()]  # remove NA

    id_counts = defaultdict(int)
    fasta_records = []
    header_map = {}  # maps header -> sequence

    for _, row in df.iterrows():
        strain_id = row["Ids"]
        seq = row["Consensus_Repeat"]
        id_counts[strain_id] += 1
        header = f"{strain_id}_{id_counts[strain_id]}"
        record = SeqRecord(Seq(seq), id=header, description="")
        fasta_records.append(record)
        header_map[header] = seq

    with open(output_fasta, "w") as out_fasta:
        SeqIO.write(fasta_records, out_fasta, "fasta")

    return header_map

def cluster_sequences(header_map):
    items = list(header_map.items())
    G = nx.Graph()

    for h, s in items:
        G.add_node(h, sequence=s)

    for i in range(len(items)):
        h1, s1 = items[i]
        for j in range(i+1, len(items)):
            h2, s2 = items[j]
            if distance(s1, s2) <= 1:
                G.add_edge(h1, h2)

    clusters = list(nx.connected_components(G))
    cluster_result = []

    for cluster_id, members in enumerate(clusters, start=1):
        for header in members:
            cluster_result.append((cluster_id, header))

    return cluster_result

def write_clusters(cluster_result, output_path):
    df = pd.DataFrame(cluster_result, columns=["Cluster_ID", "Header_ID"])
    df.to_csv(output_path, sep="\t", index=False)

def main():
    args = parse_args()
    header_map = load_and_write_fasta(args.input, args.output_fasta)
    cluster_result = cluster_sequences(header_map)
    write_clusters(cluster_result, args.output_clusters)

if __name__ == "__main__":
    main()
