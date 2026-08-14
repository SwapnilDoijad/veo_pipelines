#!/usr/bin/env python

import argparse
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
import io
from collections import defaultdict

def parse_args():
    parser = argparse.ArgumentParser(description="Extract GFF features by keyword and crop DNA region with coordinate adjustment.")
    parser.add_argument("-i", "--input", required=True, help="Input GFF file with embedded FASTA")
    parser.add_argument("-o", "--output", required=True, help="Output GFF file (cropped and adjusted)")
    parser.add_argument("-g", "--gene", required=True, help="Keyword to include (e.g., 'nif')")
    parser.add_argument("-n", "--drop", default="", help="Comma-separated exclusion keywords")
    return parser.parse_args()

def split_gff_fasta(file_path):
    gff_lines, fasta_lines = [], []
    in_fasta = False
    with open(file_path) as f:
        for line in f:
            if line.strip().startswith("##FASTA"):
                in_fasta = True
                continue
            if in_fasta:
                fasta_lines.append(line)
            else:
                gff_lines.append(line)
    return gff_lines, fasta_lines

def main():
    args = parse_args()
    include_kw = args.gene.lower()
    exclude_kws = [x.strip().lower() for x in args.drop.split(",") if x.strip()]

    gff_lines, fasta_lines = split_gff_fasta(args.input)

    header_lines = [line for line in gff_lines if line.startswith("#")]
    data_lines = [line for line in gff_lines if not line.startswith("#")]

    kept_lines = []
    contig_coords = defaultdict(list)  # {contig: [(start, end, original_line)]}
    unknown_gene_counter = 1

    for line in data_lines:
        line_lower = line.lower()
        if include_kw not in line_lower:
            continue
        if any(ex in line_lower for ex in exclude_kws):
            continue

        fields = line.strip().split("\t")
        if len(fields) < 9:
            continue

        try:
            contig = fields[0]
            start = int(fields[3])
            end = int(fields[4])
        except ValueError:
            continue

        attributes = fields[8]
        if "gene=" not in attributes:
            attributes += f";gene=unknown_{unknown_gene_counter}"
            unknown_gene_counter += 1
        fields[8] = attributes

        contig_coords[contig].append((start, end, "\t".join(fields)))

    if not contig_coords:
        print("No matching features found.")
        return

    # Load FASTA
    fasta_io = io.StringIO("".join(fasta_lines))
    fasta_dict = SeqIO.to_dict(SeqIO.parse(fasta_io, "fasta"))

    with open(args.output, "w") as out:
        out.write("##gff-version 3\n")

        for contig, entries in contig_coords.items():
            if contig not in fasta_dict:
                print(f"Warning: {contig} not found in FASTA.")
                continue

            starts = [s for s, _, _ in entries]
            ends = [e for _, e, _ in entries]
            min_start = min(starts)
            max_end = max(ends)

            new_seq = fasta_dict[contig].seq[min_start - 1:max_end]
            new_contig_name = f"{contig}_{include_kw}_region"

            # Write updated header
            out.write(f"##sequence-region {new_contig_name} 1 {len(new_seq)}\n")

            # Rewrite features with updated coordinates
            for start, end, line in entries:
                fields = line.split("\t")
                fields[0] = new_contig_name
                fields[3] = str(start - min_start + 1)
                fields[4] = str(end - min_start + 1)
                out.write("\t".join(fields) + "\n")

        out.write("##FASTA\n")

        for contig, entries in contig_coords.items():
            if contig not in fasta_dict:
                continue
            starts = [s for s, _, _ in entries]
            ends = [e for _, e, _ in entries]
            min_start = min(starts)
            max_end = max(ends)
            new_seq = fasta_dict[contig].seq[min_start - 1:max_end]
            new_contig_name = f"{contig}_{include_kw}_region"
            record = SeqRecord(new_seq, id=new_contig_name, description="cropped region")
            SeqIO.write(record, out, "fasta")

if __name__ == "__main__":
    main()








## old  and working code
    # import argparse
    # from Bio import SeqIO
    # from Bio.SeqRecord import SeqRecord
    # import io
    # from collections import defaultdict

    # def parse_args():
    #     parser = argparse.ArgumentParser(description="Extract GFF features by keyword and crop DNA region with coordinate adjustment.")
    #     parser.add_argument("-i", "--input", required=True, help="Input GFF file with embedded FASTA")
    #     parser.add_argument("-o", "--output", required=True, help="Output GFF file (cropped and adjusted)")
    #     parser.add_argument("-g", "--gene", required=True, help="Keyword to include (e.g., 'nif')")
    #     parser.add_argument("-n", "--drop", default="", help="Comma-separated exclusion keywords")
    #     return parser.parse_args()

    # def split_gff_fasta(file_path):
    #     gff_lines, fasta_lines = [], []
    #     in_fasta = False
    #     with open(file_path) as f:
    #         for line in f:
    #             if line.strip().startswith("##FASTA"):
    #                 in_fasta = True
    #                 continue
    #             if in_fasta:
    #                 fasta_lines.append(line)
    #             else:
    #                 gff_lines.append(line)
    #     return gff_lines, fasta_lines

    # def main():
    #     args = parse_args()
    #     include_kw = args.gene.lower()
    #     exclude_kws = [x.strip().lower() for x in args.drop.split(",") if x.strip()]

    #     gff_lines, fasta_lines = split_gff_fasta(args.input)

    #     header_lines = [line for line in gff_lines if line.startswith("#")]
    #     data_lines = [line for line in gff_lines if not line.startswith("#")]

    #     kept_lines = []
    #     contig_coords = defaultdict(list)  # {contig: [(start, end, original_line)]}

    #     for line in data_lines:
    #         line_lower = line.lower()
    #         if include_kw not in line_lower:
    #             continue
    #         if any(ex in line_lower for ex in exclude_kws):
    #             continue
    #         fields = line.strip().split("\t")
    #         if len(fields) >= 5:
    #             try:
    #                 contig = fields[0]
    #                 start = int(fields[3])
    #                 end = int(fields[4])
    #                 contig_coords[contig].append((start, end, line.strip()))
    #             except ValueError:
    #                 continue

    #     if not contig_coords:
    #         print("No matching features found.")
    #         return

    #     # Load FASTA
    #     fasta_io = io.StringIO("".join(fasta_lines))
    #     fasta_dict = SeqIO.to_dict(SeqIO.parse(fasta_io, "fasta"))

    #     with open(args.output, "w") as out:
    #         out.write("##gff-version 3\n")

    #         for contig, entries in contig_coords.items():
    #             if contig not in fasta_dict:
    #                 print(f"Warning: {contig} not found in FASTA.")
    #                 continue

    #             starts = [s for s, _, _ in entries]
    #             ends = [e for _, e, _ in entries]
    #             min_start = min(starts)
    #             max_end = max(ends)

    #             new_seq = fasta_dict[contig].seq[min_start - 1:max_end]
    #             new_contig_name = f"{contig}_{include_kw}_region"

    #             # Write updated header
    #             out.write(f"##sequence-region {new_contig_name} 1 {len(new_seq)}\n")

    #             # Rewrite features with updated coordinates
    #             for start, end, line in entries:
    #                 fields = line.split("\t")
    #                 fields[0] = new_contig_name
    #                 fields[3] = str(start - min_start + 1)
    #                 fields[4] = str(end - min_start + 1)
    #                 out.write("\t".join(fields) + "\n")

    #         out.write("##FASTA\n")

    #         for contig, entries in contig_coords.items():
    #             if contig not in fasta_dict:
    #                 continue
    #             starts = [s for s, _, _ in entries]
    #             ends = [e for _, e, _ in entries]
    #             min_start = min(starts)
    #             max_end = max(ends)
    #             new_seq = fasta_dict[contig].seq[min_start - 1:max_end]
    #             new_contig_name = f"{contig}_{include_kw}_region"
    #             record = SeqRecord(new_seq, id=new_contig_name, description="cropped region")
    #             SeqIO.write(record, out, "fasta")

    # if __name__ == "__main__":
    #     main()
