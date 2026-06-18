#!/bin/bash

## 20260618
## Extract sequences from a large FASTA file using GNU Parallel

# Function to print script usage
print_usage() {
    echo "Usage: $0 -i <input_fasta> -f <list_file> -o <output_folder> -p <num_processes>"
    exit 1
}

# Parse command-line arguments
while getopts "i:f:o:p:" opt; do
    case $opt in
        i) input_fasta="$OPTARG" ;;
        f) list_file="$OPTARG" ;;
        o) output_folder="$OPTARG" ;;
        p) num_processes="$OPTARG" ;;
        *) print_usage ;;
    esac
done

# Check required arguments
if [[ -z "$input_fasta" || -z "$list_file" || -z "$output_folder" || -z "$num_processes" ]]; then
    print_usage
fi

# Create output directory
mkdir -p "$output_folder"

# Function to extract a sequence and write to a file
extract_sequence() {
    header="$1"
    fasta="$2"
    outdir="$3"

    sequence=$(awk -v h="$header" '
        /^>/ {
            id=substr($1,2)  
            flag=(id ~ "^" h)
            next
            }
            flag
    ' "$fasta")

    if [[ -n "$sequence" ]]; then
        {
            echo ">$header"
            echo "$sequence"
        } > "$outdir/$header.fasta"
    else
        echo "WARNING: $header not found" >&2
    fi
}

# Export function for GNU Parallel
export -f extract_sequence

# Process headers in parallel
cat "$list_file" | \
/home/groups/VEO/tools/parallel/v20230822/src/parallel \
    -j "$num_processes" \
    extract_sequence {} "$input_fasta" "$output_folder"

echo "Done."