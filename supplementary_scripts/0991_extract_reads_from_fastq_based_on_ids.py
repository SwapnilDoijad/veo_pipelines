import argparse

def extract_reads_by_ids(fastq_file_path, read_ids_set):
    extracted_reads = {}
    current_read_lines = []
    current_read_id = None

    with open(fastq_file_path, 'r') as fastq_file:
        for line in fastq_file:
            current_read_lines.append(line)
            if len(current_read_lines) == 4:  # Each read has four lines in FASTQ format
                read_id = current_read_lines[0][1:].strip()  # Remove '@' and whitespace
                if read_id in read_ids_set:
                    extracted_reads[read_id] = ''.join(current_read_lines)
                current_read_lines = []

    return extracted_reads

def main():
    parser = argparse.ArgumentParser(description='Extract reads from a FASTQ file based on read IDs')
    parser.add_argument('-r', '--read-ids-file', required=True, help='Path to file containing read IDs')
    parser.add_argument('-f', '--fastq-file', required=True, help='Path to FASTQ file')
    parser.add_argument('-o', '--output-file', required=True, help='Path to output file')

    args = parser.parse_args()

    with open(args.read_ids_file, 'r') as f:
        read_ids = {line.strip() for line in f.readlines()}  # Using a set for faster membership check

    extracted_reads = extract_reads_by_ids(args.fastq_file, read_ids)

    with open(args.output_file, 'w') as output:
        for read_id, extracted_read in extracted_reads.items():
            output.write(extracted_read)

if __name__ == '__main__':
    main()
