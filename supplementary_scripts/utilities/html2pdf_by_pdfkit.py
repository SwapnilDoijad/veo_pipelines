import pdfkit
import argparse

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Convert HTML to PDF")
parser.add_argument("-i", "--input", required=True, help="Path to the input HTML file")
parser.add_argument("-o", "--output", required=True, help="Path to the output PDF file")
args = parser.parse_args()

# Read HTML content from input file
with open(args.input, 'r') as html_file:
    html_content = html_file.read()

# Convert HTML content to PDF
pdfkit.from_string(html_content, args.output)

print(f"Conversion complete. PDF saved to: {args.output}")
