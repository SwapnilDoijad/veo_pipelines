#!/usr/bin/env python3
import argparse
import os

# All common NCBI top-level nodes
domains = {
    "Unclassified": "0",              # Kraken 'U' reads
    "Bacteria": "2",                  # Bacteria
    "Archaea": "2157",                 # Archaea
    "Eukaryota": "2759",               # Eukaryotes
    "Viruses": "10239",                # Viruses
    "Viroids": "12884",                # Viroids (RNA pathogens)
    "Other_sequences": "12908",        # Synthetic constructs
    "Environmental_samples": "256318", # Environmental samples node
    "Unclassified_sequences": "28384"  # Special NCBI bin for unclassified seqs
}

def split_report(input_file, output_dir):
    with open(input_file) as f:
        lines = f.readlines()

    for name, taxid in domains.items():
        out_lines = []
        capture = False
        base_indent = None
        for line in lines:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 6:
                continue
            this_taxid = parts[4]
            name_field = parts[5]

            # start capturing
            if this_taxid == taxid:
                capture = True
                base_indent = len(name_field) - len(name_field.lstrip())
                out_lines.append(line)
                continue

            if capture:
                indent = len(name_field) - len(name_field.lstrip())
                # stop when indent back to base level or less
                if indent <= base_indent:
                    break
                out_lines.append(line)

        if out_lines:
            with open(os.path.join(output_dir, f"{name}_report.txt"), "w") as out_f:
                out_f.writelines(out_lines)

def main():
    parser = argparse.ArgumentParser(description="Split Kraken2 report into domain-level files.")
    parser.add_argument("-i", "--input", required=True, help="Input Kraken2 report.txt")
    parser.add_argument("-o", "--output", required=True, help="Output directory for split files")
    args = parser.parse_args()

    os.makedirs(args.output, exist_ok=True)
    split_report(args.input, args.output)

if __name__ == "__main__":
    main()
