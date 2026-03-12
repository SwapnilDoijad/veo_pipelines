import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime, timedelta

# Read data from the input file
input_path = '/home/xa73pav/scripts/general_maintainance/tmp/logs/002/users_activity.tsv'
try:
    with open(input_path, 'r') as file:
        lines = file.readlines()
except FileNotFoundError:
    raise SystemExit(f"Input file not found: {input_path}")

# Process the data
names = []
data_3rd_column = []
data_4th_column = []
for line in lines:
    line = line.strip()
    if not line:
        continue
    parts = line.split('\t')  # Split by tab
    # Need at least 3 columns (name + two numeric columns)
    if len(parts) < 3:
        continue
    # Interpret the last two columns as the numeric values (handles leading tabs)
    try:
        v3 = float(parts[-2])
        v4 = float(parts[-1])
    except (ValueError, IndexError):
        continue
    # Skip rows where either numeric column is 0
    if v3 == 0 or v4 == 0:
        continue
    # Use the remaining fields (everything except the last two) as the name.
    # Join with spaces and remove non-printable/control characters to avoid glyph warnings
    raw_name = ' '.join(p for p in parts[:-2] if p).strip()
    # Remove non-printable characters (e.g., tabs, control codes)
    name = ''.join(ch for ch in raw_name if ch.isprintable())
    if not name:
        name = 'unknown'
    names.append(name)
    data_3rd_column.append(v3)
    data_4th_column.append(v4)

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





