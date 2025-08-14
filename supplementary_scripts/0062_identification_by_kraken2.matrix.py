import pandas as pd
import glob
import os
import argparse

# Argument parser
parser = argparse.ArgumentParser(description="Merge files into species matrix.")
parser.add_argument("-i", "--input", required=True, help="Input folder containing files")
parser.add_argument("-o", "--output", required=True, help="Output TSV file name")
args = parser.parse_args()

# Get all files from input folder
file_paths = glob.glob(os.path.join(args.input, "*"))

if not file_paths:
    raise FileNotFoundError(f"No files found in {args.input}")

dfs = []
for file in file_paths:
    # Read file (assuming tab-separated)
    df = pd.read_csv(file, sep="\t")
    df = df.set_index('name')
    # Take everything before first dot in filename
    sample_name = os.path.basename(file).split('.')[0]
    df.columns = [sample_name]
    dfs.append(df)

# Merge, fill NaNs with 0, and round to 4 decimal places
merged_df = pd.concat(dfs, axis=1).fillna(0).round(4)

# Save as tab-separated file
merged_df.to_csv(args.output, sep="\t")

print(f"Matrix saved to {args.output} (tab-separated)")


## input 
# name	fraction_total_reads
# Streptomyces_sp._CdTB01	0.00051
# Streptomyces_sp._Y1	0.00051
# Streptomyces_sp._Li-HN-5-11	0.00037
# Streptomyces_sp._So13.3	0.00034
# Streptomyces_sp._NBC_01198	0.00036
# Streptomyces_sp._NHF165	0.00033
# Streptomyces_sp._NBC_01190	0.00033
# Streptomyces_sp._NBC_01476	0.00034
# Streptomyces_sp._NBC_01477	0.00033
# Streptomyces_sp._NBC_01497	0.00028
# Streptomyces_sp._R39	0.00031
# Streptomyces_sp._NBC_00631	0.00032