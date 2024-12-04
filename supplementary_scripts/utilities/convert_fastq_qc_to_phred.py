import argparse
import gzip
import os

def convert_fastq_qc_to_phred(quality_string):
    phred_scores = [ord(qc) - 33 for qc in quality_string]
    return phred_scores

def open_file(filename, mode='r'):
    """
    Open a file, using gzip if the filename ends with '.gz'.
    """
    if filename.endswith('.gz'):
        if 't' in mode:
            mode = mode.replace('t', '')  # Remove 't' if present
        return gzip.open(filename, mode + 'b')  # Binary mode is required for gzip
    return open(filename, mode)

def main(input_file, output_file):
    quality_count = [0] * 101  # Array to count scores from 0 to 100
    total_bases = 0  # Total number of bases

    with open_file(input_file, 'rt') as f_in, open_file(output_file, 'wt') as f_out:
        for line in f_in:
            if isinstance(line, bytes):  # Decode if the line is in bytes
                line = line.decode('utf-8')
            if line.startswith('@'):
                read_id = line.strip()
                sequence = f_in.readline().strip()
                if isinstance(sequence, bytes):  # Decode sequence if in bytes
                    sequence = sequence.decode('utf-8')
                f_in.readline()  # Skip the '+' separator line
                quality_string = f_in.readline().strip()
                if isinstance(quality_string, bytes):  # Decode quality_string if in bytes
                    quality_string = quality_string.decode('utf-8')
                
                # Convert sequence to space-separated
                spaced_sequence = ' '.join(sequence)
                
                # Convert quality scores to Phred scores
                phred_scores = convert_fastq_qc_to_phred(quality_string)
                phred_scores_str = ' '.join(map(str, phred_scores))
                
                # Count quality scores in the range 1 to 100
                for score in phred_scores:
                    if 1 <= score <= 100:
                        quality_count[score] += 1
                    total_bases += 1
                
                # Write the output
                f_out.write(f"{read_id}\n{spaced_sequence}\n+\n{phred_scores_str}\n")
    
    # Write summary of quality scores to a separate file
    summary_file = f"{output_file}.txt"
    with open(summary_file, 'w') as f_summary:
        f_summary.write("Quality score counts and percentages:\n")
        f_summary.write(f"Total bases: {total_bases}\n\n")
        for score in range(1, 101):
            count = quality_count[score]
            percentage = (count / total_bases) * 100 if total_bases > 0 else 0
            f_summary.write(f"Score {score}: {count} ({percentage:.2f}%)\n")
    print(f"Quality score counts and percentages written to {summary_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert QC values in FASTQ file to Phred scores.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ file (.fastq or .fastq.gz)")
    parser.add_argument("-o", "--output", required=True, help="Output file to store converted Phred scores")
    args = parser.parse_args()

    main(args.input, args.output)
