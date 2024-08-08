import argparse
import pandas as pd
import matplotlib.pyplot as plt
import random

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Create a stacked plot for a given rank.')
    parser.add_argument('-i', '--input', type=str, required=True, help='Input file (.tsv)')
    parser.add_argument('-r', '--rank', type=str, required=True, help='Rank to plot')
    parser.add_argument('-o', '--output', type=str, required=True, help='Output file (.png)')
    args = parser.parse_args()

    # Load the data
    df = pd.read_csv(args.input)

    # Filter the dataframe based on the specified rank
    df = df[df['rank'] == args.rank]

    # Drop the 'rank' column as it's no longer needed
    df.drop(columns=['rank'], inplace=True)

    # Set the 'clade' column as index
    df.set_index('clade', inplace=True)

    # Transpose the dataframe
    df = df.transpose()

    # Define a custom color palette with distinct colors
    num_clades = len(df.columns)
    # custom_palette = plt.cm.get_cmap('tab20', num_clades)
    # Mapping of color names with shades to hexadecimal RGB values
    color_mapping = {
        'light violet': '#D8BFD8',
        'very light violet': '#E6E6FA',
        'medium violet': '#8A2BE2',
        'dark violet': '#9400D3',
        'very dark violet': '#4B0082',
        'light indigo': '#4B0082',
        'very light indigo': '#9370DB',
        'medium indigo': '#5D478B',
        'dark indigo': '#3D2B1F',
        'very dark indigo': '#0B0080',
        'light blue': '#ADD8E6',
        'very light blue': '#B0E0E6',
        'medium blue': '#0000FF',
        'dark blue': '#0000CD',
        'very dark blue': '#00008B',
        'light green': '#90EE90',
        'very light green': '#98FB98',
        'medium green': '#008000',
        'dark green': '#006400',
        'very dark green': '#2E8B57',
        'light yellow': '#FFFFE0',
        'very light yellow': '#FFFFF0',
        'medium yellow': '#FFFF00',
        'dark yellow': '#FFD700',
        'very dark yellow': '#B8860B',
        'light orange': '#FFA07A',
        'very light orange': '#FAF0E6',
        'medium orange': '#FFA500',
        'dark orange': '#FF8C00',
        'very dark orange': '#FF4500',
        'light red': '#FFB6C1',
        'very light red': '#FFC0CB',
        'medium red': '#FF0000',
        'dark red': '#8B0000',
        'very dark red': '#800000',
    }

    # Define a custom color palette with color names and shades
    custom_palette = [
        color_mapping['light violet'],
        color_mapping['very light violet'],
        color_mapping['medium violet'],
        color_mapping['dark violet'],
        color_mapping['very dark violet'],
        color_mapping['light indigo'],
        color_mapping['very light indigo'],
        color_mapping['medium indigo'],
        color_mapping['dark indigo'],
        color_mapping['very dark indigo'],
        color_mapping['light blue'],
        color_mapping['very light blue'],
        color_mapping['medium blue'],
        color_mapping['dark blue'],
        color_mapping['very dark blue'],
        color_mapping['light green'],
        color_mapping['very light green'],
        color_mapping['medium green'],
        color_mapping['dark green'],
        color_mapping['very dark green'],
        color_mapping['light yellow'],
        color_mapping['very light yellow'],
        color_mapping['medium yellow'],
        color_mapping['dark yellow'],
        color_mapping['very dark yellow'],
        color_mapping['light orange'],
        color_mapping['very light orange'],
        color_mapping['medium orange'],
        color_mapping['dark orange'],
        color_mapping['very dark orange'],
        color_mapping['light red'],
        color_mapping['very light red'],
        color_mapping['medium red'],
        color_mapping['dark red'],
        color_mapping['very dark red'],
    ]

    # Shuffle the custom palette
    random.shuffle(custom_palette)

    # Plot the stacked bar chart with the custom color palette
    ax = df.plot(kind='bar', stacked=True, figsize=(15, 8), color=custom_palette)

    # Add labels and title
    ax.set_xlabel('Samples')
    ax.set_ylabel('Percentage')
    ax.set_title(f'Stacked Plot of {args.rank}')

    # Show the plot
    handles, labels = ax.get_legend_handles_labels()
    top_20_indices = df.sum().sort_values(ascending=False).index[:20]
    top_20_handles = [handles[labels.index(clade)] for clade in top_20_indices]
    top_20_labels = [clade for clade in top_20_indices]
    ax.legend(top_20_handles, top_20_labels, title=args.rank, bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()
    plt.savefig(args.output)
    plt.show()

if __name__ == "__main__":
    main()



###############################################################################

# import argparse
# import pandas as pd
# import matplotlib.pyplot as plt
# from matplotlib.colors import ListedColormap
# from matplotlib.cm import hsv
# import math
# import numpy as np

# def generate_colormap(number_of_distinct_colors: int = 80):
#     if number_of_distinct_colors == 0:
#         number_of_distinct_colors = 80

#     number_of_shades = 7
#     number_of_distinct_colors_with_multiply_of_shades = int(math.ceil(number_of_distinct_colors / number_of_shades) * number_of_shades)

#     # Create an array with uniformly drawn floats taken from <0, 1) partition
#     linearly_distributed_nums = np.arange(number_of_distinct_colors_with_multiply_of_shades) / number_of_distinct_colors_with_multiply_of_shades

#     # We are going to reorganise monotonically growing numbers in such way that there will be single array with saw-like pattern
#     #     but each saw tooth is slightly higher than the one before
#     # First divide linearly_distributed_nums into number_of_shades sub-arrays containing linearly distributed numbers
#     arr_by_shade_rows = linearly_distributed_nums.reshape(number_of_shades, number_of_distinct_colors_with_multiply_of_shades // number_of_shades)

#     # Transpose the above matrix (columns become rows) - as a result each row contains saw tooth with values slightly higher than row above
#     arr_by_shade_columns = arr_by_shade_rows.T

#     # Keep number of saw teeth for later
#     number_of_partitions = arr_by_shade_columns.shape[0]

#     # Flatten the above matrix - join each row into single array
#     nums_distributed_like_rising_saw = arr_by_shade_columns.reshape(-1)

#     # HSV colour map is cyclic (https://matplotlib.org/tutorials/colors/colormaps.html#cyclic), we'll use this property
#     initial_cm = hsv(nums_distributed_like_rising_saw)

#     lower_partitions_half = number_of_partitions // 2
#     upper_partitions_half = number_of_partitions - lower_partitions_half

#     # Modify lower half in such way that colours towards beginning of partition are darker
#     # First colours are affected more, colours closer to the middle are affected less
#     lower_half = lower_partitions_half * number_of_shades
#     for i in range(3):
#         initial_cm[0:lower_half, i] *= np.arange(0.2, 1, 0.8/lower_half)

#     # Modify second half in such way that colours towards end of partition are less intense and brighter
#     # Colours closer to the middle are affected less, colours closer to the end are affected more
#     for i in range(3):
#         for j in range(upper_partitions_half):
#             modifier = np.ones(number_of_shades) - initial_cm[lower_half + j * number_of_shades: lower_half + (j + 1) * number_of_shades, i]
#             modifier = j * modifier / upper_partitions_half
#             initial_cm[lower_half + j * number_of_shades: lower_half + (j + 1) * number_of_shades, i] += modifier

#     return ListedColormap(initial_cm)

# def main():
#     # Parse command-line arguments
#     parser = argparse.ArgumentParser(description='Create a stacked plot for a given rank.')
#     parser.add_argument('-i', '--input', type=str, required=True, help='Input file (.tsv)')
#     parser.add_argument('-r', '--rank', type=str, required=True, help='Rank to plot')
#     parser.add_argument('-o', '--output', type=str, required=True, help='Output file (.png)')
#     args = parser.parse_args()

#     # Load the data
#     df = pd.read_csv(args.input)

#     # Filter the dataframe based on the specified rank
#     df = df[df['rank'] == args.rank]

#     # Drop the 'rank' column as it's no longer needed
#     df.drop(columns=['rank'], inplace=True)

#     # Set the 'clade' column as index
#     df.set_index('clade', inplace=True)

#     # Transpose the dataframe
#     df = df.transpose()

#     # Generate a custom colormap
#     custom_cmap = generate_colormap(len(df.columns))

#     # Plot the stacked bar chart with the custom colormap
#     ax = df.plot(kind='bar', stacked=True, figsize=(15, 8), colormap=custom_cmap)

#     # Add labels and title
#     ax.set_xlabel('Samples')
#     ax.set_ylabel('Percentage')
#     ax.set_title(f'Stacked Plot of {args.rank}')

#     # Show the plot
#     handles, labels = ax.get_legend_handles_labels()
#     top_20_indices = df.sum().sort_values(ascending=False).index[:20]
#     top_20_handles = [handles[labels.index(clade)] for clade in top_20_indices]
#     top_20_labels = [clade for clade in top_20_indices]
#     ax.legend(top_20_handles, top_20_labels, title=args.rank, bbox_to_anchor=(1.05, 1), loc='upper left')
#     plt.tight_layout()
#     plt.savefig(args.output)
#     plt.show()

# if __name__ == "__main__":
#     main()
