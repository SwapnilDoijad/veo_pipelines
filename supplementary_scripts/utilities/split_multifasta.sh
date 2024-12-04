#!/bin/bash

## 20240203: worked with multifasta file with 25M fasta sequences

# Check if correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 -i input_fasta_file -o output_folder"
    exit 1
fi

while getopts "i:o:" opt; do
    case $opt in
        i) input_file="$OPTARG" ;;
        o) output_folder="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Create the output directory if it doesn't exist
mkdir -p "$output_folder"

# Variables for tracking the current header and sequence
current_header=""
current_sequence=""

# Function to write an individual fasta file
write_fasta_file() {
    local header="$1"
    local sequence="$2"
    local filename="$output_folder/${header}.fasta"
    echo -e ">$header\n$sequence" > "$filename"
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
