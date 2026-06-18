#!/bin/bash

mkdir -p "$PWD/parallel_tmp"
export TMPDIR="$PWD/parallel_tmp"

while getopts "i:o:" opt; do
    case $opt in
        i) input_file="$OPTARG" ;;
        o) output_folder="$OPTARG" ;;
        *) echo "Usage: $0 -i input.fasta -o output_folder"; exit 1 ;;
    esac
done

if [ -z "$input_file" ] || [ -z "$output_folder" ]; then
    echo "Usage: $0 -i input.fasta -o output_folder"
    exit 1
fi

mkdir -p "$output_folder"

awk -v outdir="$output_folder" '
BEGIN {
    RS=">"
    ORS=""
}

NR > 1 {
    n = split($0, lines, "\n")

    header = lines[1]
    sub(/ .*/, "", header)

    outfile = outdir "/" header ".fasta"

    print ">" lines[1] "\n" > outfile

    for(i=2;i<=n;i++) {
        if(lines[i] != "")
            print lines[i] "\n" > outfile
    }

    close(outfile)
}
' "$input_file"