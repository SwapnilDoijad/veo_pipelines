import pandas as pd
import argparse

def filter_tsne(input_file, output_file, t1_threshold, t2_threshold):
    # Load the data
    data = pd.read_csv(input_file, sep='\t')
    
    # Apply the filtering criteria
    filter_criteria = (data['t-SNE_Component_1'] > t1_threshold) & (data['t-SNE_Component_2'] < t2_threshold)
    filtered_data = data[filter_criteria]
    
    # Save the filtered data to the output file
    filtered_data.to_csv(output_file, sep='\t', index=False)
    
    # Print the filtered Read_IDs to the console
    print("Filtered Read_IDs:")
    print(filtered_data['Read_ID'].tolist())

if __name__ == "__main__":
    # Set up argparse
    parser = argparse.ArgumentParser(description="Filter data based on t-SNE_Component_1 and t-SNE_Component_2 thresholds.")
    parser.add_argument('-i', '--input', required=True, help="Input file path (tab-separated).")
    parser.add_argument('-o', '--output', required=True, help="Output file path (tab-separated).")
    parser.add_argument('-T1', type=float, required=True, help="Threshold for t-SNE_Component_1 (greater than).")
    parser.add_argument('-T2', type=float, required=True, help="Threshold for t-SNE_Component_2 (less than).")

    # Parse the arguments
    args = parser.parse_args()

    # Call the function with the parsed arguments
    filter_tsne(args.input, args.output, args.T1, args.T2)
