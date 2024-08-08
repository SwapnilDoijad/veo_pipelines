import os
import pandas as pd

# Read file paths from filepath.txt
with open("results/0067_identification_contigs_by_CAT_BAT_RAT/tmp/tmp_files/filepath.txt", "r") as file:
    file_paths = file.read().splitlines()

# Read data from files without headers
dfs = [pd.read_csv(file, delimiter='\t', header=None, names=["rank", "clade", "value"]) for file in file_paths]

# Merge dataframes
merged_df = pd.concat(dfs, axis=0)

# Create pivot table
pivot_table = merged_df.pivot_table(index=["rank", "clade"], columns=merged_df.groupby(level=0).cumcount(), values="value", fill_value=0)

# Reset index
pivot_table.reset_index(inplace=True)

# Rename columns with file names
file_names = [os.path.basename(file).split('.')[0] for file in file_paths]
column_names = ["rank", "clade"] + [f"{file_name}" for file_name in file_names]
pivot_table.columns = column_names

# Write the combined table to a file
pivot_table.to_csv("results/0067_identification_contigs_by_CAT_BAT_RAT/tmp/tmp_files/combined_table.csv", index=False)
