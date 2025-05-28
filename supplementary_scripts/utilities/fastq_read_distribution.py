import argparse
import gzip
from collections import Counter

def process_fastq(input_file, output_file, max_out_file=None):
    try:
        open_func = gzip.open if input_file.endswith('.gz') else open
        length_counts = Counter()

        with open_func(input_file, 'rt') as infile, open(output_file, 'wt') as outfile:
            max_out = open(max_out_file, 'wt') if max_out_file else None
            
            if max_out:
                max_out.write("Read_ID\tLength\n")  # Write header for max_out file

            while True:
                header = infile.readline().strip()
                if not header:
                    break  # End of file
                
                if not header.startswith('@'):  # Ensure it's a valid FASTQ header
                    print(f"Warning: Unexpected format in {input_file}, line: {header}")
                    continue
                
                read_id = header.split()[0][1:]  # Extract read ID (remove '@')
                sequence = infile.readline().strip()
                infile.readline()  # Skip '+'
                infile.readline()  # Skip quality line
                
                read_length = len(sequence)
                length_counts[read_length] += 1
                
                if max_out:
                    max_out.write(f"{read_id}\t{read_length}\n")  # Write read ID and length
            
            if max_out:
                max_out.close()

            # Write length distribution to output file
            outfile.write("Length\tCount\n")  # Add header for clarity
            for length, count in sorted(length_counts.items()):
                outfile.write(f"{length}\t{count}\n")

        print(f"Read length distribution saved to {output_file}")
        if max_out_file:
            print(f"Per-read lengths saved to {max_out_file}")

    except FileNotFoundError:
        print(f"Error: File not found - {input_file}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compute read length distribution from a FASTQ file.")
    parser.add_argument('-i', '--input', required=True, help='Path to input FASTQ file (can be .gz)')
    parser.add_argument('-o', '--output', required=True, help='Path to output file for length distribution')
    parser.add_argument('-max_out', '--max_output', help='Optional: Path to TSV file for per-read lengths')

    args = parser.parse_args()
    process_fastq(args.input, args.output, args.max_output)
