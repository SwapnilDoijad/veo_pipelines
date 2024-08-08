import argparse
import gzip

def chop_sequences(input_file, output_file, chunk_length=150):
    with gzip.open(input_file, 'rt') as f_in, gzip.open(output_file, 'wt') as f_out:
        while True:
            # Read the header line
            header = f_in.readline().strip()
            if not header:
                break  # End of file
            # Read the sequence line
            sequence = f_in.readline().strip()
            # Read the plus line
            f_in.readline()
            # Read the quality line
            quality = f_in.readline().strip()

            # Chop the sequence into chunks of chunk_length
            num_chunks = (len(sequence) + chunk_length - 1) // chunk_length
            for i in range(num_chunks):
                chopped_sequence = sequence[i * chunk_length: (i + 1) * chunk_length]
                chopped_quality = quality[i * chunk_length: (i + 1) * chunk_length]

                # Modify the header to include the prefix
                chopped_header = f"@chop{i + 1}_{header[1:]}\n"

                # Write to the output file
                f_out.write(chopped_header)
                f_out.write(f"{chopped_sequence}\n+\n{chopped_quality}\n")

def main():
    parser = argparse.ArgumentParser(description="Chop sequences in a FASTQ file into chunks of a specified length.")
    parser.add_argument("-i", "--input", help="Input gzip-compressed FASTQ file", required=True)
    parser.add_argument("-o", "--output", help="Output gzip-compressed FASTQ file", required=True)
    parser.add_argument("-l", "--length", type=int, default=150, help="Length of each chunk (default: 150)")
    args = parser.parse_args()

    chop_sequences(args.input, args.output, args.length)

if __name__ == "__main__":
    main()
