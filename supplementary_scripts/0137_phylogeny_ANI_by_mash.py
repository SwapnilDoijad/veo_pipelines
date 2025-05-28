import argparse

def process_file(input_file, output_file, keyword):
    genomo_counter = 1

    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            line = line.strip()
            if not line:
                continue  # Skip empty lines
            
            parts = line.split('\t')
            last_column = parts[-1]
            items = last_column.split(',')

            # Find the first item containing the keyword
            match = next((item for item in items if keyword in item), None)

            if match:
                prefix = match
            else:
                prefix = f"genomospecies_{genomo_counter:03}"
                genomo_counter += 1

            new_line = f"{prefix}\t{line}\n"
            outfile.write(new_line)

    print(f"Processed lines written to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prefix lines based on keyword match or serial label.")
    parser.add_argument("-i", "--input", required=True, help="Input file path")
    parser.add_argument("-o", "--output", required=True, help="Output file path")
    parser.add_argument("-n", "--name", required=True, help="Keyword to match (e.g., Rhizobium)")

    args = parser.parse_args()

    process_file(args.input, args.output, args.name)
