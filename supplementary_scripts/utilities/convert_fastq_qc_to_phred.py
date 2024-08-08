## this script convert the phred score of each base (that is stored in ASCII characters) in human-redable format

## usage: python convert_qc_to_phred.py -i input.fastq -o output.txt

import argparse

def convert_fastq_qc_to_phred(quality_string):
    phred_scores = [ord(qc) - 33 for qc in quality_string]
    return phred_scores

def main(input_file, output_file):
    with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out:
        for line in f_in:
            if line.startswith('@'):
                read_id = line.strip()
                sequence = f_in.readline().strip()
                f_in.readline()  # Skip the '+' separator line
                quality_string = f_in.readline().strip()
                phred_scores = convert_fastq_qc_to_phred(quality_string)
                phred_scores_str = ' '.join(map(str, phred_scores))
                f_out.write(f"{read_id}\n{sequence}\n+\n{phred_scores_str}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert QC values in FASTQ file to Phred scores.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ file")
    parser.add_argument("-o", "--output", required=True, help="Output file to store converted Phred scores")
    args = parser.parse_args()

    main(args.input, args.output)
