import argparse
import pandas as pd
from collections import Counter

def tsv_to_vcf(input_tsv, output_vcf):
    # Read and parse the TSV, preserving the header
    with open(input_tsv, 'r') as f:
        lines = f.readlines()

    header_line = [line for line in lines if line.startswith('#')][-1]
    header = header_line.lstrip('#').strip().split('\t')
    data_lines = [line.strip().split('\t') for line in lines if not line.startswith('#')]

    # Deduplicate column names (e.g., AO, DP, etc.)
    counter = Counter()
    new_columns = []
    for col in header:
        counter[col] += 1
        new_col = f"{col}_{counter[col]}" if counter[col] > 1 else col
        new_columns.append(new_col)

    df = pd.DataFrame(data_lines, columns=new_columns)

    # Set format fields as used in VCF sample column
    format_fields = ['GT', 'AD', 'AO', 'DP', 'PL', 'QA', 'QR', 'RO']
    sample_format_map = {}
    for f in format_fields:
        matches = [col for col in df.columns if col.startswith(f)]
        if matches:
            sample_format_map[f] = matches[0]  # Use the first occurrence

    with open(output_vcf, 'w') as vcf:
        # Write VCF headers
        vcf.write("##fileformat=VCFv4.2\n")
        vcf.write("##source=TSV_to_VCF_converter\n")
        vcf.write("##INFO=<ID=SPLIT_STATUS,Number=1,Type=String,Description=\"Indicates if the SNP was split from a complex variant\">\n")
        for f in format_fields:
            vcf.write(f"##FORMAT=<ID={f},Number=1,Type=String,Description=\"Sample field {f}\">\n")
        vcf.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tunknown\n")

        for _, row in df.iterrows():
            # Basic VCF fields
            chrom = row.get('CHROM', '.')
            pos = row.get('POS', '.')
            vid = row.get('ID', '.')
            ref = row.get('REF', '.')
            alt = row.get('ALT', '.')
            qual = row.get('QUAL', '.')
            filt = row.get('FILTER', '.')

            # INFO fields (exclude FORMAT/sample and standard fields)
            standard_fields = {'CHROM', 'POS', 'ID', 'REF', 'ALT', 'QUAL', 'FILTER'}
            excluded = set(sample_format_map.values()).union({'SPLIT_STATUS'})
            info_cols = [col for col in df.columns if col not in standard_fields and col not in excluded]
            info_str = ";".join([f"{col.split('_')[0]}={row[col]}" for col in info_cols if row[col] != '' and row[col] != '.'])

            # Add SPLIT_STATUS
            split_status_col = [col for col in df.columns if col.startswith('SPLIT_STATUS')][0]
            info_str += f";SPLIT_STATUS={row[split_status_col]}"

            # FORMAT and sample fields
            format_str = ':'.join(format_fields)
            sample_str = ':'.join([
                str(row[sample_format_map[f]]) if f in sample_format_map and pd.notna(row[sample_format_map[f]]) else '.'
                for f in format_fields
            ])

            # Replace '-' with symbolic <DEL>
            if ref == '-':
                ref = '<DEL>'
            if alt == '-':
                alt = '<DEL>'

            # Write VCF line
            vcf.write(f"{chrom}\t{pos}\t{vid}\t{ref}\t{alt}\t{qual}\t{filt}\t{info_str}\t{format_str}\t{sample_str}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert TSV with VCF content back to VCF format.")
    parser.add_argument("-i", "--input", required=True, help="Input TSV file")
    parser.add_argument("-o", "--output", required=True, help="Output VCF file")
    args = parser.parse_args()

    tsv_to_vcf(args.input, args.output)
