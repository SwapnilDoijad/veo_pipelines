import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime, timedelta

# Read data from the input file
with open('/home/xa73pav/scripts/general_maintainance/tmp/logs/002/users_activity.tsv', 'r') as file:
    lines = file.readlines()

# Process the data
names = []
data_3rd_column = []
data_4th_column = []
for line in lines:
    parts = line.strip().split('\t')  # Split by tab
    # Skip rows where either the 3rd or 4th column is 0
    if float(parts[2]) == 0 or float(parts[3]) == 0:
        continue
    names.append(parts[0])
    data_3rd_column.append(float(parts[2]))
    data_4th_column.append(float(parts[3]))

# Set the width of the bars
bar_width = 0.35
index = np.arange(len(names))

# Create the figure and the subplot
fig, ax = plt.subplots(figsize=(12, 6))

# Plot the data from the 3rd column
bar1 = ax.bar(index, data_3rd_column, bar_width, label='CPU', color='skyblue')

# Plot the data from the 4th column
bar2 = ax.bar(index + bar_width, data_4th_column, bar_width, label='Memory', color='lightgreen')

# Set labels, title, and ticks
ax.set_xlabel('Names')
ax.set_ylabel('CPU/Memory hours (log-scale)')
# Calculate the date range
end_date = datetime.now()
start_date = end_date - timedelta(days=30)
date_range = f"{start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}"
# Update the title with real dates
ax.set_title(f'Draco: CPU and Memory Usage of Users ({date_range})')
ax.set_xticks(index + bar_width / 2)
ax.set_xticklabels(names, rotation=90)
ax.legend()

# Set y-axis to log scale
plt.yscale('log')

# Save the figure
plt.tight_layout()
plt.savefig('/home/xa73pav/scripts/general_maintainance/tmp/logs/002/users_activity.png')

# Show the plot
plt.show()





