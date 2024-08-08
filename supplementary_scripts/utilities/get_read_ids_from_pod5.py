import os
import pod5
import argparse

# source /home/groups/VEO/tools/pod5/v0.2.2/bin/activate

# Function to extract read IDs from a single POD5 file and write them to the output file
def get_and_write_read_ids(pod5_file, output_file):
    with pod5.Reader(pod5_file) as reader:
        with open(output_file, 'a') as f:  # Open the file in append mode
            for record in reader:
                f.write(f"{record.read_id}\n")

# Function to process all POD5 files in a directory
def process_directory(directory, output_file):
    for filename in os.listdir(directory):
        if filename.endswith(".pod5"):
            pod5_file_path = os.path.join(directory, filename)
            get_and_write_read_ids(pod5_file_path, output_file)

# Main function to parse arguments and execute the script
def main():
    parser = argparse.ArgumentParser(description="Extract read IDs from POD5 files in a directory.")
    parser.add_argument('-d', '--directory', required=True, help="Input directory containing POD5 files")
    parser.add_argument('-o', '--output', required=True, help="Output file to save read IDs")
    args = parser.parse_args()

    directory = args.directory
    output_file = args.output

    # Process all POD5 files in the specified directory
    process_directory(directory, output_file)

if __name__ == "__main__":
    main()
