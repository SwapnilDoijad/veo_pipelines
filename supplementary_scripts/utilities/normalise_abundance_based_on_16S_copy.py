import pandas as pd
import argparse

def main():
    parser = argparse.ArgumentParser(description="Normalize 16S abundance by rrnDB copy number")
    parser.add_argument("-i", "--input", required=True, help="Input abundance file (TSV)")
    parser.add_argument("-o", "--output", required=True, help="Output normalized abundance file (TSV)")
    parser.add_argument("-r", "--rrndb", required=True, help="rrnDB RDP stats file (TSV)")
    args = parser.parse_args()

    abund_df = pd.read_csv(args.input, sep='\t')

    def extract_genus_species(tax_string):
        parts = tax_string.split(';')
        genus = parts[5].strip() if len(parts) > 5 else None
        species = parts[6].strip() if len(parts) > 6 else None
        return pd.Series([genus, species])

    abund_df[['genus', 'species']] = abund_df['lineage'].apply(extract_genus_species)

    rrndb_df = pd.read_csv(args.rrndb, sep='\t')

    rrndb_df = rrndb_df.rename(columns={
        'name': 'taxon',
        'mean': 'mean_copy_number'
    })

    def split_rrndb_taxon(taxon):
        parts = str(taxon).split()
        genus = parts[0] if len(parts) > 0 else None
        species = parts[1] if len(parts) > 1 else None
        return pd.Series([genus, species])

    rrndb_df[['genus_rrn', 'species_rrn']] = rrndb_df['taxon'].apply(split_rrndb_taxon)

    merged_df = pd.merge(
        abund_df,
        rrndb_df[['genus_rrn', 'species_rrn', 'mean_copy_number']],
        left_on=['genus', 'species'],
        right_on=['genus_rrn', 'species_rrn'],
        how='left'
    )

    no_species_match = merged_df['mean_copy_number'].isna()
    if no_species_match.any():
        genus_only_df = pd.merge(
            abund_df.loc[no_species_match].drop(columns=['genus', 'species']),
            rrndb_df[['genus_rrn', 'mean_copy_number']].drop_duplicates(subset=['genus_rrn']),
            left_on=abund_df.loc[no_species_match, 'genus'],
            right_on='genus_rrn',
            how='left'
        )
        merged_df.loc[no_species_match, 'mean_copy_number'] = genus_only_df['mean_copy_number'].values

    merged_df['mean_copy_number'] = merged_df['mean_copy_number'].fillna(1)

    sample_cols = [col for col in abund_df.columns if col not in ['lineage', 'genus', 'species']]

    for col in sample_cols:
        merged_df[col] = merged_df[col] / merged_df['mean_copy_number']

    merged_df[sample_cols] = merged_df[sample_cols].round(3)

    def norm_status(cn):
        if cn == 1:
            return "NOTnormalized_1_16S_meanCopyNumber"
        else:
            return f"normalized_{cn}_16S_meanCopyNumber"

    merged_df['normalization_by_16S_meanCopyNumber'] = merged_df['mean_copy_number'].apply(norm_status)

    output_cols = ['normalization_by_16S_meanCopyNumber', 'lineage'] + sample_cols
    normalized_df = merged_df[output_cols]

    normalized_df.to_csv(args.output, sep='\t', index=False)

    print(f"Normalization complete. Output saved to {args.output}")

if __name__ == "__main__":
    main()
