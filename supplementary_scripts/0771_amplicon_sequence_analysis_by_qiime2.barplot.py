import pandas as pd
import matplotlib.pyplot as plt

# Load CSV file into a pandas DataFrame
df = pd.read_csv('results/0771_amplicon_sequence_analysis_by_qiime2/raw_files/bar-plot-exported/level-7.csv')
# Set the 'index' column as the index of the DataFrame
df.set_index('index', inplace=True)
# Group the data by 'organ' and 'treatment' columns, and sum the counts
grouped_data = df.groupby(['organ', 'treatment']).sum()

# Plotting
grouped_data.plot(kind='bar', stacked=True, figsize=(10, 6))
plt.title('Amplicon Sequence Analysis by QIIME2')
plt.xlabel('Sample')
plt.ylabel('Counts')
plt.xticks(rotation=45, ha='right')  # Rotate x-axis labels for better readability
plt.legend(title='Treatment')
plt.tight_layout()  # Adjust layout to prevent clipping of labels

# Save the plot as an image file (e.g., PNG, PDF, SVG)
plt.savefig('results/0771_amplicon_sequence_analysis_by_qiime2/raw_files/bar-plot-exported/level-7.csv.png', dpi=300)  # Change the file extension as needed
