#!/bin/bash

# Input arguments
vcf_file=""
bam_file=""
output_file=""

# Parse command-line options
while getopts "v:b:o:" opt; do
    case ${opt} in
        v ) # VCF file
            vcf_file=$OPTARG
            ;;
        b ) # BAM file
            bam_file=$OPTARG
            ;;
        o ) # Output file
            output_file=$OPTARG
            ;;
        \? ) echo "Usage: cmd [-v vcf_file] [-b bam_file] [-o output_file]"
            exit 1
            ;;
    esac
done

# Check if VCF and BAM files are provided
if [[ -z "$vcf_file" || -z "$bam_file" || -z "$output_file" ]]; then
    echo "VCF file (-v), BAM file (-b), and output file (-o) must be specified."
    exit 1
fi

# Step 1: Count total number of reads in the BAM file
total_reads=$(samtools view -c "$bam_file")
echo "Total number of reads in BAM file: $total_reads"

# Step 2: Extract variant positions from the VCF file
bcftools query -f '%CHROM\t%POS\n' "$vcf_file" > variant_positions.txt

# Step 3: Extract reads overlapping the variant positions (i.e., reads carrying variants) with headers
samtools view -h -L variant_positions.txt "$bam_file" > reads_with_variants.sam

# Step 4: Count the number of reads in the extracted SAM file (those overlapping variant positions)
variant_supporting_reads=$(samtools view -c reads_with_variants.sam)
echo "Number of reads supporting variants (SNP/INS/DEL): $variant_supporting_reads"

# Step 5: Calculate the number of reads that do not carry any variants
non_variant_reads=$((total_reads - variant_supporting_reads))
echo "Number of reads that do not carry variants (supporting reference): $non_variant_reads"

# Step 6: Output results to the specified output file
echo -e "Total_Reads\tVariant_Supporting_Reads\tNon_Variant_Reads" > "$output_file"
echo -e "$total_reads\t$variant_supporting_reads\t$non_variant_reads" >> "$output_file"

# Clean up temporary files
rm variant_positions.txt
rm reads_with_variants.sam

echo "Results saved to $output_file"
