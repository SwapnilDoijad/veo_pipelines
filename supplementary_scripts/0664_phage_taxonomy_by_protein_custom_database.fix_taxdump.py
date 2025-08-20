import argparse
from pathlib import Path

# Set up argument parser
parser = argparse.ArgumentParser(description="Process ICTV taxdump files.")
parser.add_argument("--input-dir", required=True, help="Path to the input directory containing ICTV taxdump files.")
parser.add_argument("--output-dir", required=True, help="Path to the output directory for modified files.")
args = parser.parse_args()

# Define paths based on user input
input_dir = Path(args.input_dir)
output_dir = Path(args.output_dir)

taxid_mapping_dict = {}
count = 1
with open(input_dir.joinpath("names.dmp")) as fin:
    for line in fin:
        taxid = line.split("\t")[0]
        taxid_mapping_dict[taxid] = str(count)
        count += 1

with open(input_dir.joinpath("names.dmp")) as fin, open(
    output_dir.joinpath("names.dmp.new"), "w"
) as fout:
    for line in fin:
        line = line.strip().split("\t")
        line[0] = taxid_mapping_dict[line[0]]
        line = "\t".join(line)
        fout.write(f"{line}\n")

with open(input_dir.joinpath("nodes.dmp")) as fin, open(
    output_dir.joinpath("nodes.dmp.new"), "w"
) as fout:
    for line in fin:
        line = line.strip().split("\t")
        line[0] = taxid_mapping_dict[line[0]]
        line[2] = taxid_mapping_dict[line[2]]
        line = "\t".join(line)
        fout.write(f"{line}\n")

# Replace original files with modified ones
input_dir.joinpath("names.dmp").unlink()
input_dir.joinpath("nodes.dmp").unlink()
output_dir.joinpath("nodes.dmp.new").rename(input_dir.joinpath("nodes.dmp"))
output_dir.joinpath("names.dmp.new").rename(input_dir.joinpath("names.dmp"))