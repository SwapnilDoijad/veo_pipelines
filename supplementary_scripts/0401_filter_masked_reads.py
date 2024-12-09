import gzip
import argparse

def calculate_n_percentage(input_file):
    """
    Calculate the total percentage of 'N' bases in the FASTQ file.
    """
    total_bases = 0
    total_n_bases = 0

    with gzip.open(input_file, 'rt') as infile:
        while True:
            # Read a single record (4 lines)
            header = infile.readline()
            if not header:
                break
            sequence = infile.readline().strip()
            plus = infile.readline()
            quality = infile.readline()

            # Count total bases and 'N' bases
            total_bases += len(sequence)
            total_n_bases += sequence.count('N')

    # Calculate percentage
    n_percentage = (total_n_bases / total_bases) * 100 if total_bases > 0 else 0
    return total_n_bases, total_bases, n_percentage

def filter_reads(input_file, output_file, max_n_percentage):
    """
    Filter reads with more than a certain percentage of 'N' bases.
    """
    with gzip.open(input_file, 'rt') as infile, gzip.open(output_file, 'wt') as outfile:
        while True:
            # Read a single record (4 lines)
            header = infile.readline()
            if not header:
                break
            sequence = infile.readline().strip()
            plus = infile.readline()
            quality = infile.readline()

            # Calculate percentage of 'N'
            n_count = sequence.count('N')
            n_percentage = (n_count / len(sequence)) * 100

            # Write the record only if 'N' percentage is within limit
            if n_percentage <= max_n_percentage:
                outfile.write(header)
                outfile.write(sequence + "\n")
                outfile.write(plus)
                outfile.write(quality)

def write_summary(tsv_output, total_bases, total_n_bases, n_percentage):
    """
    Write the summary of total bases, 'N' bases, and their percentage to a TSV file.
    """
    with open(tsv_output, 'w') as tsvfile:
        tsvfile.write(f"Total_Bases\tTotal_N_Bases\tPercentage_N\n")
        tsvfile.write(f"{total_bases}\t{total_n_bases}\t{n_percentage:.2f}\n")

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Filter FASTQ reads with more than a certain percentage of 'N' bases and calculate overall 'N' percentage in the file.")
    parser.add_argument('-i', '--input', required=True, help="Input FASTQ.gz file")
    parser.add_argument('-o', '--output', required=True, help="Output FASTQ.gz file")
    parser.add_argument('-p', '--percentage', type=float, required=True, help="Maximum percentage of 'N' allowed in a read")

    args = parser.parse_args()

    # Generate the TSV output file name based on the percentage
    tsv_output = args.output.replace(".fastq.gz", f"_{args.percentage}.tsv")

    # Calculate the total percentage of 'N' bases
    print("Calculating total percentage of 'N' bases in the input file...")
    total_n_bases, total_bases, n_percentage = calculate_n_percentage(args.input)
    print(f"Total bases: {total_bases}")
    print(f"Total 'N' bases: {total_n_bases}")
    print(f"Percentage of 'N' bases: {n_percentage:.2f}%")

    # Write the summary to the TSV file
    write_summary(tsv_output, total_bases, total_n_bases, n_percentage)
    print(f"Summary written to {tsv_output}")

    # Filter the reads
    print("Filtering reads with more than the specified percentage of 'N' bases...")
    filter_reads(args.input, args.output, args.percentage)
    print(f"Filtered reads written to {args.output}")

if __name__ == "__main__":
    main()
