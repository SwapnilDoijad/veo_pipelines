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

# Function to write an individual fasta file
write_fasta_file() {
    local header="$1"
    local sequence="$2"
    local filename="$output_folder/${header}.fasta"
    echo -e ">$header\n$sequence" > "$filename"
}

# Function to process a chunk of the multifasta file
process_chunk() {
    local chunk="$1"
    local temp_file="$(mktemp)"
    awk -v RS='>' 'NR>1{print ">"$0}' "$chunk" | 
    while IFS= read -r line; do
        local header=$(echo "$line" | awk '{print $1}')
        local sequence=$(echo "$line" | awk '{print substr($0,length($1)+2)}')
        write_fasta_file "$header" "$sequence"
    done
    rm -f "$temp_file"
}

# Export the functions to make them available to parallel
export -f write_fasta_file
export -f process_chunk

# Split the input file into chunks and process them in parallel
split --numeric-suffixes=1 -n l/80 -a 4 "$input_file" temp_chunk_
ls temp_chunk_* | /home/groups/VEO/tools/parallel/v20230822/src/parallel -j 80 process_chunk {}

# Remove temporary files
rm -f temp_chunk_*

