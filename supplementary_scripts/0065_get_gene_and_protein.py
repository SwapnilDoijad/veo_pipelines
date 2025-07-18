import argparse

def parse_gff(gff_file):
    cds_features = []
    with open(gff_file, 'r') as f:
        for line in f:
            if line.startswith('#') or '\tCDS\t' not in line:
                continue
            parts = line.strip().split('\t')
            chrom = parts[0]
            start = int(parts[3])
            end = int(parts[4])
            attributes = parse_attributes(parts[8])
            cds_features.append((chrom, start, end, attributes))
    return cds_features

def parse_attributes(attr_str):
    attrs = {}
    for item in attr_str.split(';'):
        if '=' in item:
            key, val = item.split('=', 1)
            attrs[key] = val
    return attrs

def find_matching_feature(chrom, pos, cds_features, annotation=""):
    # 1. Try to find overlapping CDS
    for feature in cds_features:
        f_chrom, start, end, attrs = feature
        if f_chrom == chrom and start <= pos <= end:
            gene = attrs.get('gene', '').replace(' ', '_') or 'unknown'
            product = attrs.get('product', '').replace(' ', '_') or 'unknown'
            return gene, product

    # 2. If upstream_gene_variant, find closest downstream CDS
    if "upstream_gene_variant" in annotation:
        downstream = [
            f for f in cds_features if f[0] == chrom and f[1] > pos
        ]
        if downstream:
            next_feature = min(downstream, key=lambda x: x[1])
            attrs = next_feature[3]
            gene = attrs.get('gene', '').replace(' ', '_') or 'unknown'
            product = attrs.get('product', '').replace(' ', '_') or 'unknown'
            return gene, product

    # 3. Default fallback
    return 'unknown', 'unknown'

def annotate_variants(input_file, output_file, gff_file):
    cds_features = parse_gff(gff_file)

    with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
        header = fin.readline().strip()
        fout.write(header + "\tGene\tProduct\n")

        for line in fin:
            parts = line.strip().split('\t')
            if len(parts) < 3:
                continue  # skip invalid lines

            chrom = parts[0]  # Assuming CHROM is column 1
            pos = int(parts[1])  # Assuming POS is column 2
            annotation = parts[-1]  # Assuming annotation is in last column

            gene, product = find_matching_feature(chrom, pos, cds_features, annotation)
            fout.write(line.strip() + f"\t{gene}\t{product}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Annotate variant file with gene and product info from GFF.")
    parser.add_argument("-i", "--input", required=True, help="Input variant file (tab-delimited).")
    parser.add_argument("-o", "--output", required=True, help="Output annotated file.")
    parser.add_argument("-g", "--gff", required=True, help="Input GFF3 file.")
    args = parser.parse_args()

    annotate_variants(args.input, args.output, args.gff)
