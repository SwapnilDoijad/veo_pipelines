import matplotlib.pyplot as plt
import numpy as np

# Read data from the input file
with open('tmp/002_users_activity.tsv', 'r') as file:
    lines = file.readlines()

# Process the data
names = []
data_3rd_column = []
data_4th_column = []
for line in lines:
    parts = line.strip().split()
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
ax.set_title('Draco: CPU and Memory Usage of Users in the Last 30 Days')
ax.set_xticks(index + bar_width / 2)
ax.set_xticklabels(names, rotation=90)
ax.legend()

# Set y-axis to log scale
plt.yscale('log')

# Save the figure
plt.tight_layout()
plt.savefig('tmp/002_users_activity.png')

# Show the plot
plt.show()





