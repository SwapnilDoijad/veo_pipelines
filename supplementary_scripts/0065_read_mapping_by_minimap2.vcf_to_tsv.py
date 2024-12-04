import csv
import argparse

# Dictionary of descriptions for each VCF field
field_descriptions = {
    '#CHROM': "Chromosome or contig name where the variant is located",
    'POS': "Position of the variant in the reference genome",
    'ID': "Variant identifier (can be a '.' if not known)",
    'REF': "Reference allele (the nucleotide in the reference genome)",
    'ALT': "Alternate allele(s) (the nucleotide(s) different from the reference)",
    'QUAL': "Quality score of the variant call (higher scores indicate higher confidence)",
    'FILTER': "Indicates if the variant passed filtering criteria (can be '.' if no filtering applied)",
    'AB': "Allele Balance. Proportion of reads showing the reference allele versus the alternate allele",
    'ABP': "Allele Balance Probability. Phred-scaled probability of observing the deviation by chance",
    'AC': "Allele Count. Number of alternate alleles observed in the sample(s)",
    'AF': "Allele Frequency. Estimated frequency of the alternate allele (0 to 1 scale)",
    'AN': "Total number of alleles considered for this variant across all samples",
    'AO': "Alternate Observations. Number of reads supporting the alternate allele",
    'CIGAR': "CIGAR string describing the alignment of the alternate allele",
    'DP': "Total Read Depth. Total number of reads covering this position",
    'DPB': "Read Depth per Base. Total read depth per base at the locus",
    'DPRA': "Depth Ratio. Depth ratio for the alternate allele",
    'EPP': "End Placement Probability for the alternate allele",
    'EPPR': "End Placement Probability for the reference allele",
    'GTI': "Genotyping Iterations. Number of iterations the genotyping algorithm required",
    'LEN': "Length of the variant (number of base pairs)",
    'MEANALT': "Mean number of alternate alleles observed per sample",
    'MQM': "Mean Mapping Quality for the alternate allele",
    'MQMR': "Mean Mapping Quality for the reference allele",
    'NS': "Number of Samples. Number of samples with data for this variant",
    'NUMALT': "Number of alternate alleles at the variant site",
    'ODDS': "Odds Ratio. The odds ratio of the variant genotype being correct",
    'PAIRED': "Proportion of paired reads supporting the alternate allele",
    'PAIREDR': "Proportion of paired reads supporting the reference allele",
    'PAO': "Partial Alternate Observations. Alternate allele observations counted fractionally",
    'PQA': "Phred-scaled quality of alternate allele observations",
    'PQR': "Phred-scaled quality of reference allele observations",
    'PRO': "Partial Reference Observations. Reference allele observations counted fractionally",
    'QA': "Sum of quality scores for the alternate allele",
    'QR': "Sum of quality scores for the reference allele",
    'RO': "Reference Observations. Number of reads supporting the reference allele",
    'RPL': "Reads Placed Left. Reads supporting the alternate allele aligned to the left of the variant",
    'RPP': "Read Placement Probability for the alternate allele",
    'RPPR': "Read Placement Probability for the reference allele",
    'RPR': "Reads Placed Right. Reads supporting the alternate allele aligned to the right of the variant",
    'RUN': "Run Length. Length of consecutive repeats of the alternate allele",
    'SAF': "Alternate Forward Reads. Number of alternate allele reads on the forward strand",
    'SAP': "Strand Balance Probability for the alternate allele",
    'SAR': "Alternate Reverse Reads. Number of alternate allele reads on the reverse strand",
    'SRF': "Reference Forward Reads. Number of reference allele reads on the forward strand",
    'SRP': "Strand Balance Probability for the reference allele",
    'SRR': "Reference Reverse Reads. Number of reference allele reads on the reverse strand",
    'TYPE': "Type of variant (e.g., snp, del, ins, etc.)",
    'AD': "Allele Depth. Number of reads supporting each allele (reference and alternate)",
    'GL': "Genotype Likelihood. Likelihood of the sample having different genotypes",
    'GT': "Genotype of the sample (e.g., 0/1 for heterozygous, 0/0 for homozygous reference)"
}

def write_field_descriptions(tsvfile):
    """
    Writes the descriptions of VCF fields as comments in the TSV file.
    """
    for field, description in field_descriptions.items():
        tsvfile.write(f"# {field}: {description}\n")

def parse_vcf_info(info_str):
    """
    Parses the INFO field of a VCF file and returns a dictionary of the key-value pairs.
    """
    info_dict = {}
    for entry in info_str.split(';'):
        if '=' in entry:
            key, value = entry.split('=', 1)
            info_dict[key] = value
        else:
            info_dict[entry] = None
    return info_dict

def parse_format_and_sample(format_str, sample_str):
    """
    Parses the FORMAT and SAMPLE fields of a VCF file. The FORMAT defines the fields in SAMPLE.
    Returns a dictionary of sample data based on FORMAT.
    """
    format_fields = format_str.split(':')
    sample_values = sample_str.split(':')
    
    # Create a dictionary where keys are FORMAT fields and values are SAMPLE values
    sample_dict = dict(zip(format_fields, sample_values))
    
    return sample_dict

def vcf_to_tsv(vcf_file, output_tsv):
    """
    Converts a VCF file to a TSV file, decoding INFO, FORMAT, and SAMPLE fields.
    """
    with open(vcf_file, 'r') as vcf, open(output_tsv, 'w', newline='') as tsvfile:
        # Write descriptions of each field as comments
        write_field_descriptions(tsvfile)
        
        writer = csv.writer(tsvfile, delimiter='\t')
        
        info_keys = set()  # To track all INFO keys encountered for column headers
        format_keys = set()  # To track all FORMAT keys encountered
        
        # First, pass to collect all possible INFO and FORMAT keys for header
        header_written = False
        for line in vcf:
            if line.startswith('##'):
                continue
            if line.startswith('#CHROM'):
                header = line.strip().split('\t')
                continue

            fields = line.strip().split('\t')
            info_dict = parse_vcf_info(fields[7])
            info_keys.update(info_dict.keys())
            
            format_dict = parse_format_and_sample(fields[8], fields[9])
            format_keys.update(format_dict.keys())
            
            # Write the header once (excluding the entire INFO column)
            if not header_written:
                tsv_header = header[:7] + sorted(info_keys) + sorted(format_keys)
                writer.writerow(tsv_header)
                header_written = True

        # Reset file pointer to reprocess the lines
        vcf.seek(0)
        
        # Second pass to write the data rows
        for line in vcf:
            if line.startswith('##'):
                continue
            if line.startswith('#CHROM'):
                continue
            
            fields = line.strip().split('\t')
            
            # Process INFO field (expand it into individual key-value pairs)
            info_dict = parse_vcf_info(fields[7])
            info_values = [info_dict.get(key, '') for key in sorted(info_keys)]
            
            # Process FORMAT and SAMPLE fields
            format_dict = parse_format_and_sample(fields[8], fields[9])
            format_values = [format_dict.get(key, '') for key in sorted(format_keys)]
            
            # Write the row (excluding the entire INFO column)
            tsv_row = fields[:7] + info_values + format_values
            writer.writerow(tsv_row)

def main():
    # Setup argparse to handle input and output files
    parser = argparse.ArgumentParser(description='Convert VCF to TSV format with decoded INFO, FORMAT, and SAMPLE fields.')
    parser.add_argument('-i', '--input', required=True, help='Input VCF file')
    parser.add_argument('-o', '--output', required=True, help='Output TSV file')

    args = parser.parse_args()

    # Convert the VCF file to a TSV file
    vcf_to_tsv(args.input, args.output)

if __name__ == "__main__":
    main()
