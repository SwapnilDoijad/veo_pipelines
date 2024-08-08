import argparse

def find_sequences_in_fastq(pattern1, pattern2, fastq_file, output_file):
    try:
        with open(fastq_file, 'r') as f:
            with open(output_file, 'w') as out:
                while True:
                    header = f.readline().strip()
                    seq = f.readline().strip()
                    plus = f.readline().strip()
                    quality = f.readline().strip()

                    if not quality:
                        break

                    if pattern1 in seq and pattern2 in seq:
                        out.write(header + '\n')

    except FileNotFoundError:
        print(f"Error: The file {fastq_file} was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Command-line arguments parsing
parser = argparse.ArgumentParser(description='Find FASTQ headers for given sequences.')
parser.add_argument('-i', '--input', required=True, help='Input FASTQ file')
parser.add_argument('-p1', '--pattern1', required=True, help='First sequence pattern to find')
parser.add_argument('-p2', '--pattern2', required=True, help='Second sequence pattern to find')
parser.add_argument('-o', '--output', required=True, help='Output file for headers')
args = parser.parse_args()

# Call the function with the provided arguments
find_sequences_in_fastq(args.pattern1, args.pattern2, args.input, args.output)
