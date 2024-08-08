import argparse

def lower_to_full(lower_matrix, headers):
    n = len(lower_matrix)
    full_matrix = [[0] * n for _ in range(n)]  # Create an n x n matrix filled with zeros

    for i in range(n):
        for j in range(i, n):  # Include the diagonal and above
            full_matrix[i][j] = lower_matrix[i][j - i]
            full_matrix[j][i] = lower_matrix[i][j - i]  # Symmetric, so also fill the lower part

    return full_matrix, headers

def read_lower_matrix(input_file):
    with open(input_file, 'r') as file:
        lines = file.readlines()
        lower_matrix = [line.strip().split('\t') for line in lines]
    return lower_matrix

def write_full_matrix(output_file, full_matrix, headers):
    with open(output_file, 'w') as file:
        # Write column headers
        file.write('\t'.join([''] + headers) + '\n')

        for i, row in enumerate(full_matrix):
            # Write row header
            file.write(headers[i] + '\t')
            
            # Write row values
            file.write('\t'.join(map(str, row)) + '\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert a lower triangular matrix to a full matrix")
    parser.add_argument("-i", "--input", required=True, help="Input file containing the lower triangular matrix")
    parser.add_argument("-o", "--output", required=True, help="Output file for the full matrix")
    args = parser.parse_args()

    lower_matrix = read_lower_matrix(args.input)
    headers = [row[0] for row in lower_matrix]
    full_matrix, headers = lower_to_full(lower_matrix, headers)
    write_full_matrix(args.output, full_matrix, headers)

    print(f"Full matrix has been written to {args.output}")
