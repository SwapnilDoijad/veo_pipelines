import argparse

# Create argument parser
parser = argparse.ArgumentParser(description='Calculate percentages based on data file.')
parser.add_argument('-i', '--input', type=str, required=True, help='Input file path')
parser.add_argument('-o', '--output', type=str, required=True, help='Output file path')

# Parse arguments
args = parser.parse_args()

# Read data from the input file
with open(args.input, "r") as file:
    data = file.readlines()

# Parse the data and calculate the total count for each category
categories = {}
total_count = 0

for line in data:
    parts = line.strip().split("\t")
    category = parts[0]
    subcategory = parts[1]
    count = int(parts[2])
    total_count += count
    if category in categories:
        categories[category].append((subcategory, count))
    else:
        categories[category] = [(subcategory, count)]

# Calculate the percentage values and write to the output file
with open(args.output, "w") as file:
    for category, subcategories in categories.items():
        category_count = sum(count for _, count in subcategories)
        for subcategory, count in subcategories:
            percentage = (count / category_count) * 100
            file.write(f"{category}\t{subcategory}\t{percentage:.4f}\n")


