import argparse
import pandas as pd
import matplotlib.pyplot as plt

def extract_taxonomic_rank(lineage, rank_idx):
    parts = lineage.split(';')
    if len(parts) > rank_idx:
        return parts[rank_idx]
    else:
        return 'Unknown'

def main(input_file, output_file, group_by, top_n):
    # Load data
    df = pd.read_csv(input_file, sep='\t')
    
    # Extract taxonomic level column based on group_by argument
    if group_by == 'lineage':
        df['group'] = df['lineage']
    elif group_by == 'family':
        df['group'] = df['lineage'].apply(lambda x: extract_taxonomic_rank(x, 4))
    elif group_by == 'genus':
        df['group'] = df['lineage'].apply(lambda x: extract_taxonomic_rank(x, 5))
    elif group_by == 'species':
        df['group'] = df['lineage'].apply(lambda x: extract_taxonomic_rank(x, 6))
    else:
        raise ValueError(f"Invalid group_by value: {group_by}. Choose from lineage, family, genus, species.")
    
    # Drop the original lineage column, group becomes new index
    df_grouped = df.drop(columns=['lineage']).groupby('group').sum()
    
    # Calculate mean abundance for ranking top N
    mean_abundance = df_grouped.mean(axis=1)
    top_groups = mean_abundance.sort_values(ascending=False).head(top_n).index
    
    # Separate top N and other groups
    df_top = df_grouped.loc[top_groups]
    df_other = df_grouped.drop(top_groups).sum(axis=0).to_frame(name='Other').T
    
    # Combine top N and other
    df_final = pd.concat([df_top, df_other])
    
    # Normalize so each sample sums to 1
    df_final = df_final.div(df_final.sum(axis=0), axis=1)
    
    # Transpose for plotting (samples on x-axis)
    df_T = df_final.T
    
    # Dynamic figure size: width based on number of samples, height fixed
    n_samples = df_T.shape[0]
    width = max(10, n_samples * 0.5)  # 0.5 inch per sample, min width 10
    height = 10
    
    # Generate colors
    num_top = len(df_final) - 1  # excluding 'Other'
    color_palette = plt.cm.tab20.colors  # 20 distinct colors
    
    if num_top > 20:
        repeats = (num_top // 20) + 1
        colors = list(color_palette) * repeats
        colors = colors[:num_top]
    else:
        colors = list(color_palette[:num_top])
    
    colors.append('#d3d3d3')  # light grey for 'Other'
    
    # Plot with custom colors
    ax = df_T.plot(kind='bar', stacked=True, figsize=(width, height), width=0.8, color=colors)
    ax.set_ylabel('Relative Abundance')
    ax.set_xlabel('Samples')
    ax.set_title(f'Relative Abundance by {group_by.capitalize()} (Top {top_n} + Other)')
    plt.xticks(rotation=45, ha='right', fontsize=8)
    plt.legend(loc='center left', bbox_to_anchor=(1, 0.5), fontsize='small')
    plt.subplots_adjust(bottom=0.25, right=0.8)
    
    # Save both PNG and SVG
    plt.savefig(output_file, dpi=300)
    svg_file = output_file.rsplit('.', 1)[0] + '.svg'
    plt.savefig(svg_file)
    
    print(f'Plots saved to:\n - {output_file}\n - {svg_file}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Plot Relative Abundance grouped by taxonomic level.')
    parser.add_argument('-i', '--input', required=True, help='Input TSV file with lineage and abundances')
    parser.add_argument('-o', '--output', required=True, help='Output plot file (png, pdf, etc.)')
    parser.add_argument('--group-by', choices=['lineage', 'family', 'genus', 'species'], default='lineage',
                        help='Taxonomic level to group by (default: lineage)')
    parser.add_argument('--top', type=int, default=20,
                        help='Number of top abundant groups to show (default: 20)')
    args = parser.parse_args()
    
    main(args.input, args.output, args.group_by, args.top)
