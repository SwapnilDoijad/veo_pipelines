import argparse
import gzip
from Bio import SeqIO

def extract_reads(input_file, output_file, id_list_file):
    # Read the list of read IDs
    with open(id_list_file, 'r') as f:
        id_list = set(line.strip() for line in f)

    # Parse the input FASTQ file and filter reads based on the provided IDs
    with get_input_handle(input_file) as in_handle:
        with gzip.open(output_file, 'wt') as out_handle:
            for record in SeqIO.parse(in_handle, 'fastq'):
                # Extract the unique ID part from the record ID
                record_id = record.id.split()[0]  # Take only the part before the first space
                if record_id in id_list:
                    SeqIO.write(record, out_handle, 'fastq')

def get_input_handle(input_file):
    # Check if the input file is compressed (ends with ".gz")
    if input_file.endswith('.gz'):
        return gzip.open(input_file, 'rt')
    else:
        return open(input_file, 'r')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extract reads from a FASTQ file based on a list of read IDs')
    parser.add_argument('-i', '--input', help='Input FASTQ file', required=True)
    parser.add_argument('-o', '--output', help='Output FASTQ.gz file', required=True)
    parser.add_argument('-l', '--id_list', help='File containing list of read IDs', required=True)
    args = parser.parse_args()

    # Ensure the output file ends with '.gz'
    if not args.output.endswith('.gz'):
        args.output += '.gz'

    # Call the extract_reads function with the provided arguments
    extract_reads(args.input, args.output, args.id_list)

# import argparse
# import gzip
# import logging
# from Bio import SeqIO

# def extract_reads(input_file, output_file, id_list_file):
#     # Configure logging
#     logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
    
#     # Read the list of read IDs
#     logging.debug(f"Reading ID list from {id_list_file}")
#     with open(id_list_file, 'r') as f:
#         id_list = set(line.strip() for line in f)
#     logging.debug(f"Total IDs loaded: {len(id_list)}")
    
#     found_count = 0
#     not_found_count = 0

#     # Parse the input FASTQ file and filter reads based on the provided IDs
#     logging.debug(f"Processing input FASTQ file: {input_file}")
#     with get_input_handle(input_file) as in_handle:
#         with gzip.open(output_file, 'wt') as out_handle:
#             for record in SeqIO.parse(in_handle, 'fastq'):
#                 # Extract the unique ID part from the record ID
#                 record_id = record.id.split()[0]  # Take only the part before the first space
#                 if record_id in id_list:
#                     SeqIO.write(record, out_handle, 'fastq')
#                     found_count += 1
#                     logging.debug(f"Read ID {record_id} found and written to output.")
#                 else:
#                     not_found_count += 1
#                     logging.debug(f"Read ID {record_id} not found in the provided ID list.")
    
#     # Log the final counts
#     logging.info(f"Extraction complete: {found_count} reads found and written to output.")
#     logging.info(f"{not_found_count} reads not found in the ID list.")

# def get_input_handle(input_file):
#     # Check if the input file is compressed (ends with ".gz")
#     logging.debug(f"Opening input file: {input_file}")
#     if input_file.endswith('.gz'):
#         return gzip.open(input_file, 'rt')
#     else:
#         return open(input_file, 'r')

# if __name__ == '__main__':
#     parser = argparse.ArgumentParser(description='Extract reads from a FASTQ file based on a list of read IDs')
#     parser.add_argument('-i', '--input', help='Input FASTQ file', required=True)
#     parser.add_argument('-o', '--output', help='Output FASTQ.gz file', required=True)
#     parser.add_argument('-l', '--id_list', help='File containing list of read IDs', required=True)
#     parser.add_argument('--debug', help='Enable debug logging', action='store_true')
#     args = parser.parse_args()

#     # Set logging level based on the debug flag
#     if args.debug:
#         logging.getLogger().setLevel(logging.DEBUG)
#     else:
#         logging.getLogger().setLevel(logging.INFO)

#     # Ensure the output file ends with '.gz'
#     if not args.output.endswith('.gz'):
#         args.output += '.gz'

#     # Call the extract_reads function with the provided arguments
#     extract_reads(args.input, args.output, args.id_list)
