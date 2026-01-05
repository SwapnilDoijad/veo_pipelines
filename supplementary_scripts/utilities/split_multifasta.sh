#!/bin/bash

## 20240203: worked with multifasta file with 25M fasta sequences

# Usage function
usage() {
    echo "Usage: $0 -i input_fasta_file -o output_folder [-p prefix]"
    echo
    echo "Options:"
    echo "  -i, --input    Input multifasta file"
    echo "  -o, --output   Output folder for split fasta files"
    echo "  -p, --prefix   Optional prefix to prepend to output file IDs (e.g. prefix_ )"
    exit 1
}

# Parse arguments (support long options)
if [ "$#" -eq 0 ]; then
    usage
fi

prefix=""
while [[ "$#" -gt 0 ]]; do
    key="$1"
    case $key in
        -i|--input)
            input_file="$2"
            shift 2
            ;;
        -o|--output)
            output_folder="$2"
            shift 2
            ;;
        -p|--prefix)
            prefix="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [ -z "${input_file}" ] || [ -z "${output_folder}" ]; then
    usage
fi

# Create the output directory if it doesn't exist
mkdir -p "$output_folder"

# Ensure prefix (if provided) ends with an underscore
if [ -n "${prefix}" ]; then
    case "${prefix}" in
        *_ ) ;;
        * ) prefix="${prefix}_" ;;
    esac
fi

# Variables for tracking the current header and sequence
current_header=""
current_sequence=""

# Function to write an individual fasta file
write_fasta_file() {
    local header="$1"
    local sequence="$2"
    local new_header="${prefix}${header}"
    local filename="$output_folder/${new_header}.fasta"
    echo -e ">${new_header}\n${sequence}" > "$filename"
}

# Read the multifasta file line by line
while IFS= read -r line; do
    if [[ $line == ">"* ]]; then
        # If the line starts with '>', it's a header line
        if [ -n "$current_header" ]; then
            # If current_header is not empty, write the previous entry
            write_fasta_file "$current_header" "$current_sequence"
        fi
        # Extract header (remove leading '>')
        current_header="${line#>}"
        current_sequence=""
    else
        # Append sequence lines
        current_sequence+="$line"
    fi
done < "$input_file"

# Write the last entry
if [ -n "$current_header" ]; then
    write_fasta_file "$current_header" "$current_sequence"
fi
