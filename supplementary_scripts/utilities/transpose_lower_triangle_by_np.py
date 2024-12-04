import argparse
import numpy as np

def read_data(file_path):
    data = {}
    with open(file_path, 'r') as file:
        for line in file:
            items = line.strip().split('\t')
            key1 = items[0]
            for i, value in enumerate(items[1:]):
                key2 = items[i+1]
                data[(key1, key2)] = float(value)
                data[(key2, key1)] = float(value)  # Filling the symmetric value
    return data

def write_matrix(matrix, output_file):
    with open(output_file, 'w') as file:
        for row in matrix:
            file.write('\t'.join(map(str, row)) + '\n')

def main(input_file, output_file):
    # Read data from input file
    data = read_data(input_file)

    # Extract unique keys
    keys = sorted(set(key for pair in data.keys() for key in pair))

    # Create an empty matrix
    matrix = np.zeros((len(keys), len(keys)))

    # Fill in the values
    for i, key1 in enumerate(keys):
        for j, key2 in enumerate(keys):
            if (key1, key2) in data:
                matrix[i, j] = data[(key1, key2)]

    # Write the matrix to the output file
    write_matrix(matrix, output_file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Create a symmetric matrix from input file.')
    parser.add_argument('-i', '--input', type=str, help='Input file path', required=True)
    parser.add_argument('-o', '--output', type=str, help='Output file path', required=True)
    args = parser.parse_args()

    main(args.input, args.output)
