#!/bin/bash

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

# Check if required arguments are provided
if [[ -z $input_fasta || -z $list_file || -z $output_folder || -z $num_processes ]]; then
    print_usage
fi

# Create output directory if it does not exist
mkdir -p $output_folder

# Read the list of headers
headers_to_extract=($(cat "$list_file"))

# Function to extract a sequence and write to a file
extract_sequence() {
    header="$1"
    sequence=$(awk -v h="$header" '/^>/{if($0~h){flag=1}else{flag=0}}flag{print}' "$input_fasta" | tail -n +2)
    echo -e ">$header\n$sequence" >  data/"$header.fasta"
}

# Export the function for parallel use
export -f extract_sequence

# Process each header in parallel
echo "${headers_to_extract[@]}" | tr ' ' '\n' | /home/groups/VEO/tools/parallel/v20230822/src/parallel -j "$num_processes" extract_sequence
