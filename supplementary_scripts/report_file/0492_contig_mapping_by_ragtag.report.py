import pandas as pd
import argparse
import sys
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors

# Argument parsing
parser = argparse.ArgumentParser(description="Convert a TSV table to a styled PDF.")
parser.add_argument('-i', '--input', required=True, help='Input TSV file')
parser.add_argument('-o', '--output', required=True, help='Output PDF file')
args = parser.parse_args()

# Validate output file extension
if not args.output.lower().endswith('.pdf'):
    print("Error: Output file must end with .pdf")
    sys.exit(1)

# Load TSV data
try:
    df = pd.read_csv(args.input, sep='\t')
except Exception as e:
    print(f"Error reading input file: {e}")
    sys.exit(1)

if df.empty:
    print("Input TSV file is empty.")
    sys.exit(1)

# Convert DataFrame to list of lists
data = [df.columns.tolist()] + df.values.tolist()

# Create PDF document
doc = SimpleDocTemplate(args.output, pagesize=A4)  # Changed from landscape(A4) to A4

# Create a title for the table
styles = getSampleStyleSheet()
title = Paragraph("Results: 0492_contig_mapping_by_ragtag", styles['Title'])

# Create the table
table = Table(data)

# Style
style = TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.darkgrey),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 12),
    ('FONTSIZE', (0, 1), (-1, -1), 10),
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, colors.black),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.whitesmoke, colors.lightgrey]),
])
table.setStyle(style)

# Build PDF
try:
    doc.build([title, Spacer(1, 12), table])  # Add title and some space before the table
    print(f"✅ PDF created: {args.output}")
except Exception as e:
    print(f"Error writing PDF: {e}")
    sys.exit(1)
