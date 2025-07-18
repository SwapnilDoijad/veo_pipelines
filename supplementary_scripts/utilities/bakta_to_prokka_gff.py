#!/usr/bin/env python3

import argparse

def fix_gff(input_gff, output_gff):
    with open(input_gff, 'r') as fin, open(output_gff, 'w') as fout:
        gene_counter = 1
        for line in fin:
            if line.startswith('#') or line.strip() == '':
                fout.write(line)
            else:
                parts = line.strip().split('\t')
                if len(parts) == 9:
                    # Parse attributes
                    attr_dict = {}
                    for attr in parts[8].split(';'):
                        if '=' in attr:
                            key, value = attr.split('=', 1)
                            attr_dict[key] = value

                    # Replace ID and Name
                    new_id = f"gene_{gene_counter:06d}"
                    attr_dict['ID'] = new_id
                    attr_dict['Name'] = new_id

                    # Rebuild the attributes string
                    parts[8] = ';'.join([f"{k}={v}" for k, v in attr_dict.items()])
                    fout.write('\t'.join(parts) + '\n')
                    gene_counter += 1
                else:
                    fout.write(line)

def main():
    parser = argparse.ArgumentParser(description="Clean a single Bakta GFF3 file for Panaroo.")
    parser.add_argument("-i", "--input", required=True, help="Input Bakta GFF3 file")
    parser.add_argument("-o", "--output", required=True, help="Output cleaned GFF3 file")
    args = parser.parse_args()

    fix_gff(args.input, args.output)
    # print(f"✅ Cleaned GFF saved to '{args.output}'")

if __name__ == "__main__":
    main()
