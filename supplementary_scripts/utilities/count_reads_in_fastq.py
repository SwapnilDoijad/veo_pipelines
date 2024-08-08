## usage: python count_reads_in_fastq.py -i input.fastq

import argparse

def count_and_divide(filename):
    try:
        with open(filename, 'r') as file:
            lines = file.readlines()
            line_count = len(lines)
            result = line_count / 4
            return result
    except FileNotFoundError:
        return "File not found."

def main():
    parser = argparse.ArgumentParser(description="Count the number of lines in a FASTQ file and divide by 4.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ file path")

    args = parser.parse_args()

    input_file = args.input
    result = count_and_divide(input_file)

    if isinstance(result, str):
        print(result)
    else:
        print(f"Number of lines divided by 4: {result}")

if __name__ == "__main__":
    main()
