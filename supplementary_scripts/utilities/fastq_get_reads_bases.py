import sys
import gzip

def open_fastq(file_path):
    if file_path.endswith('.gz'):
        return gzip.open(file_path, 'rt')
    else:
        return open(file_path, 'r')

def count_reads_and_bases(file_path):
    total_reads = 0
    total_bases = 0
    line_number = 0

    with open_fastq(file_path) as f:
        for line in f:
            line_number += 1
            if line_number % 4 == 2:  # Sequence line
                total_bases += len(line.strip())
                total_reads += 1

    return total_reads, total_bases

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python fastq_bases.py <file.fastq[.gz]>")
        sys.exit(1)

    fastq_file = sys.argv[1]
    try:
        reads, bases = count_reads_and_bases(fastq_file)
        print(f"{reads} {bases}")
    except Exception as e:
        print(f"Error reading file: {e}")
        sys.exit(1)
