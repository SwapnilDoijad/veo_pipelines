#!/bin/bash

# Initialize variables for input and output files
input_file=""
output_file=""

# Parse command-line options
while getopts "i:o:" opt; do
    case ${opt} in
        i ) # Input VCF file
            input_file=$OPTARG
            ;;
        o ) # Output TSV file
            output_file=$OPTARG
            ;;
        \? ) echo "Usage: cmd [-i input_file] [-o output_file]"
            exit 1
            ;;
    esac
done

# Check if input and output files are provided
if [[ -z "$input_file" || -z "$output_file" ]]; then
    echo "Both input (-i) and output (-o) files must be specified."
    echo "Usage: cmd [-i input_file] [-o output_file]"
    exit 1
fi

# Output header to the output file
echo -e "#ID\tCHROM\tPOS\tREF\tALT\tQUAL\tTotal_Reads_Mapped\tReads_Supporting_ALT\tReads_Supporting_REF\tSNP_Type\tAllele_Frequency\tRead_Depth_per_Base\tQualRef\tQualAllel\tSNP_Annotation" > "$output_file"

# Parse VCF file to extract relevant fields, including simplified SNP annotation
grep -v '^#' "$input_file" | awk -v OFS="\t" '
{
    # Extract basic information from each VCF line
    chrom=$1
    pos=$2
    ref=$4
    alt=$5
    qual=$6

    # If any field is empty, set it to NA
    if (qual == ".") qual="NA"
    
    # Extract INFO field and split into array by ";"
    split($8, info_fields, ";")

    # Initialize variables and set them to NA by default
    DP="NA"
    AO="NA"
    RO="NA"
    TYPE="NA"
    AF="NA"
    DPB="NA"
    QR="NA"
    QA="NA"
    ANN="NA"

    # Loop through INFO fields to find relevant information
    for (i in info_fields) {
        if (info_fields[i] ~ /^DP=/) {
            DP=substr(info_fields[i], 4)
        }
        if (info_fields[i] ~ /^AO=/) {
            AO=substr(info_fields[i], 4)
        }
        if (info_fields[i] ~ /^RO=/) {
            RO=substr(info_fields[i], 4)
        }
        if (info_fields[i] ~ /^TYPE=/) {
            TYPE=substr(info_fields[i], 6)
        }
        if (info_fields[i] ~ /^AF=/) {
            AF=substr(info_fields[i], 4)
        }
        if (info_fields[i] ~ /^DPB=/) {
            DPB=substr(info_fields[i], 5)
        }
        if (info_fields[i] ~ /^QR=/) {
            QR=substr(info_fields[i], 4)
        }
        if (info_fields[i] ~ /^QA=/) {
            QA=substr(info_fields[i], 4)
        }
        if (info_fields[i] ~ /^ANN=/) {
            # Extract the first annotation from the ANN field
            split(substr(info_fields[i], 5), ann_fields, ",")
            split(ann_fields[1], ann_details, "|")
            ANN=ann_details[1] "|" ann_details[2] "|" ann_details[3] "|" ann_details[4]
        }
    }

    # Output the columns in the desired format
    print chrom, pos, ref, alt, qual, DP, AO, RO, TYPE, AF, DPB, QR, QA, ANN
}' >> "$output_file"
