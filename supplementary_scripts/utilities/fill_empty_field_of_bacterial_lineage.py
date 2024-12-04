import argparse
import pandas as pd

def process_file(input_file, output_file):
    # Define the columns
    columns = ['0', 'k__', 'p__', 'c__', 'o__', 'f__', 'g__', 's__']

    # Read the file into a list of lines
    with open(input_file, 'r') as file:
        lines = file.readlines()

    # Initialize a list to hold the processed rows
    processed_rows = []

    # Iterate through each line in the file
    for line in lines:
        # Split the line into fields by tab
        fields = line.strip().split('\t')
        
        # Ensure the line has exactly the number of columns expected
        fields = fields[:len(columns)]
        
        # Fill in missing fields with their prefixes
        while len(fields) < len(columns):
            fields.append('')
        for i in range(len(columns)):
            if fields[i] == '':
                fields[i] = columns[i]
        
        # Add the processed row to the list
        processed_rows.append(fields)

    # Convert the list of processed rows into a DataFrame
    df = pd.DataFrame(processed_rows, columns=columns)

    # Write the DataFrame to the output file
    df.to_csv(output_file, sep='\t', index=False, header=False)

    print(f"Filled data has been saved to {output_file}")

def main():
    parser = argparse.ArgumentParser(description="Process a file and fill missing fields with their prefixes.")
    parser.add_argument('-i', '--input', required=True, help='Input file path')
    parser.add_argument('-o', '--output', required=True, help='Output file path')
    
    args = parser.parse_args()
    
    process_file(args.input, args.output)

if __name__ == '__main__':
    main()