import pandas as pd
import argparse
import glob
import os

def combine_abundance_per_file(input_dir, output_file):
    files = glob.glob(os.path.join(input_dir, '*.tsv'))
    combined_df = pd.DataFrame()

    for file in files:
        df = pd.read_csv(file, delim_whitespace=True, error_bad_lines=False, warn_bad_lines=True)
        lower_cols = {col.lower(): col for col in df.columns}

        lineage_col = lower_cols['lineage']
        abundance_col = lower_cols['abundance']

        df[lineage_col] = df[lineage_col].astype(str).str.strip().str.rstrip(';')

        df_subset = df[[lineage_col, abundance_col]].copy()
        filename = os.path.basename(file)
        sample_id = filename.split('.')[0]
        df_subset.columns = ['lineage', sample_id]

        df_subset['lineage'] = df_subset['lineage'].str.strip()

        if combined_df.empty:
            combined_df = df_subset
        else:
            combined_df['lineage'] = combined_df['lineage'].str.strip()
            combined_df = pd.merge(combined_df, df_subset, on='lineage', how='outer')

    combined_df.fillna(0, inplace=True)
    combined_df['lineage'] = combined_df['lineage'].str.rstrip(';')

    abundance_cols = combined_df.columns.difference(['lineage'])
    combined_df[abundance_cols] = combined_df[abundance_cols].round(3)

    combined_df.to_csv(output_file, sep='\t', index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Combine abundance files with lineage as rows and filenames as columns.')
    parser.add_argument('-d', '--input-directory', required=True, 
                        help='Input directory containing abundance files (.tsv)')
    parser.add_argument('-o', '--output', required=True, 
                        help='Output file name')
    
    args = parser.parse_args()
    combine_abundance_per_file(args.input_directory, args.output)
