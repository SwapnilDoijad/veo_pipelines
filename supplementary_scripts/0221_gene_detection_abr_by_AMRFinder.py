import pandas as pd
import matplotlib.pyplot as plt

# Read the TSV file into a pandas DataFrame
df = pd.read_csv('results/0221_gene_detection_abr_by_AMRFinder/Abr_gene_frequency.tsv', sep='\t', header=0)

# Sort the DataFrame by 'frequency' column in descending order and select top 25
top_25 = df.sort_values(by='frequency', ascending=False).head(25)

# Plotting the bar chart
plt.figure(figsize=(10, 6))
top_25.plot(kind='bar', x='Abr-gene', y='frequency', color='skyblue')
plt.title('Top 25 Frequencies by Abr-gene')
plt.xlabel('Abr-gene')
plt.ylabel('frequency')
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.show()
plt.savefig('results/0221_gene_detection_abr_by_AMRFinder/top_25_genes.png')
