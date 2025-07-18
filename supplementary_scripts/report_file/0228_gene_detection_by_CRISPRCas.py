import argparse
import pandas as pd
from Bio import SeqIO
from fpdf import FPDF

def parse_fasta(fasta_path):
    records = []
    for record in SeqIO.parse(fasta_path, "fasta"):
        records.append({"Header_ID": record.id, "Sequence": str(record.seq)})
    return pd.DataFrame(records)

def load_inputs(input_string):
    files = input_string.split(",")
    if len(files) != 3:
        raise ValueError("Expected three input files: cluster.tsv, metadata.tsv, sequences.fasta")
    return files[0], files[1], files[2]

class PDF(FPDF):
    def header(self):
        self.set_font("Helvetica", "B", 12)
        self.cell(0, 10, "CRISPR Cluster Report", ln=1, align="C")

    def chapter_title(self, title):
        self.set_font("Helvetica", "B", 12)
        self.set_fill_color(220, 220, 220)
        self.cell(0, 10, title, ln=1, fill=True)

    def chapter_body(self, text):
        self.set_font("Helvetica", "", 10)
        self.multi_cell(0, 5, text)
        self.ln()

def generate_pdf(cluster_df, metadata_df, sequences_df, output_path):
    merged_df = cluster_df.merge(sequences_df, on="Header_ID", how="left")
    full_df = merged_df.merge(metadata_df, left_on="Header_ID", right_on="Ids", how="left")

    entries = full_df.sort_values("Header_ID").to_dict(orient="records")

    pdf = PDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()

    for row in entries:
        header_id = row["Header_ID"]
        sequence = row.get("Sequence", "")
        seq_trim = sequence[:80] + "..." if len(sequence) > 80 else sequence

        pdf.chapter_title(f"Header_ID: {header_id}")
        body = (
            f"Cluster_ID: {row['Cluster_ID']}\n"
            f"Strain: {row.get('Strain', 'N/A')}\n"
            f"CRISPR Length: {row.get('CRISPR_Length', 'N/A')}\n"
            f"Direction: {row.get('CRISPRDirection', 'N/A')}\n"
            f"Consensus Repeat: {row.get('Consensus_Repeat', 'N/A')}\n"
            f"Sequence: {seq_trim}\n"
            "----------------------------------------"
        )
        pdf.chapter_body(body)

    pdf.output(output_path)
    print(f"✅ PDF saved to {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Generate CRISPR cluster PDF report.")
    parser.add_argument("-i", "--input", required=True, help="Comma-separated input files: cluster.tsv,metadata.tsv,sequences.fasta")
    parser.add_argument("-o", "--output", required=True, help="Output PDF file path")
    args = parser.parse_args()

    cluster_path, metadata_path, fasta_path = load_inputs(args.input)

    cluster_df = pd.read_csv(cluster_path, sep="\t")
    metadata_df = pd.read_csv(metadata_path, sep="\t")
    sequences_df = parse_fasta(fasta_path)

    generate_pdf(cluster_df, metadata_df, sequences_df, args.output)

if __name__ == "__main__":
    main()
