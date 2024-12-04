import sys

# Check if the correct number of arguments is provided
if len(sys.argv) != 5 or sys.argv[1] != "-i" or sys.argv[3] != "-o":
    print("Usage: python script_name.py -i input_file_with_path -o output_file_with_path")
    sys.exit(1)

# Get the input and output file paths from the command-line arguments
input_file_path = sys.argv[2]
output_file_path = sys.argv[4]

# Read the contents of the first file (taxonomyId_list) and store the taxonomys in a list
taxonomys_to_search = []
with open('tmp/step_3/all.taxonomy_sorted.tsv', 'r') as file:
    for line in file:
        taxonomy_id = line.strip()
        taxonomys_to_search.append(taxonomy_id)

# Initialize a dictionary to store the taxonomys and their corresponding values
taxonomy_values = {}

# Read the contents of the second file (input_file_path) and populate the dictionary
with open(input_file_path, 'r') as file:
    for line in file:
        parts = line.strip().split('\t')
        if len(parts) >= 2:  # Check if there are enough columns in the line
            taxonomy_id = parts[2]
            value = parts[1]
            taxonomy_values[taxonomy_id] = value

# Open the output file for writing
with open(output_file_path, 'w') as output_file:
    # Iterate through the taxonomys in taxonomys_to_search and write taxonomy ID and corresponding value to the output file
    for taxonomy_id in taxonomys_to_search:
        if taxonomy_id in taxonomy_values:
            output_file.write(f"{taxonomy_id}\t{taxonomy_values[taxonomy_id]}\n")  # Write taxonomy ID and value separated by tab
        else:
            output_file.write(f"{taxonomy_id}\t0\n")  # Write taxonomy ID and 0 if not found
