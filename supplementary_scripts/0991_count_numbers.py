## 20240617 not working 







import pandas as pd
import argparse

# Function to process each read_id
def process_read(read_id, blast_results):
    filtered_results = blast_results[blast_results[0] == read_id]
    if not filtered_results.empty:
        best_hit = filtered_results.sort_values(by=5).iloc[0, [0, 1]]
        mismatches = filtered_results.sort_values(by=5)[5].tolist()
        mismatches_str = '\t'.join(map(str, mismatches))
        return f"{best_hit[0]} {best_hit[1]} {mismatches_str}"
    return None

def main(input_file, output_file, blast_results_file):
    # Load read IDs
    read_ids = pd.read_csv(input_file, header=None, sep='\t')
    read_ids[0] = read_ids[0].str.replace('@', '')

    # Load BLAST results
    blast_results = pd.read_csv(blast_results_file, header=None, sep='\t')

    # Process all read IDs and collect results
    results = [process_read(read_id, blast_results) for read_id in read_ids[0]]

    # Filter out None results
    results = [result for result in results if result is not None]

    # Write the results to the output file
    with open(output_file, 'w') as f:
        for result in results:
            f.write(result + '\n')

    print("Processing complete. Results saved to", output_file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process read IDs and extract best hits from BLAST results.")
    parser.add_argument('-i', '--input', required=True, help="Input file with read IDs")
    parser.add_argument('-o', '--output', required=True, help="Output file for results")
    parser.add_argument('-b', '--blast', required=True, help="BLAST results file")

    args = parser.parse_args()
    main(args.input, args.output, args.blast)


# import pandas as pd
# import argparse
# from concurrent.futures import ProcessPoolExecutor

# # Function to process each read_id
# def process_read(read_id, blast_results):
#     filtered_results = blast_results[blast_results[0] == read_id]
#     if not filtered_results.empty:
#         best_hit = filtered_results.sort_values(by=5).iloc[0, [0, 1]]
#         mismatches = filtered_results.sort_values(by=5)[5].tolist()
#         mismatches_str = '\t'.join(map(str, mismatches))
#         return f"{best_hit[0]} {best_hit[1]} {mismatches_str}"
#     return None

# def main(input_file, output_file, blast_results_file, num_workers):
#     # Load read IDs
#     read_ids = pd.read_csv(input_file, header=None, sep='\t')
#     read_ids[0] = read_ids[0].str.replace('@', '')

#     # Load BLAST results
#     blast_results = pd.read_csv(blast_results_file, header=None, sep='\t')

#     # Process all read IDs in parallel
#     with ProcessPoolExecutor(max_workers=num_workers) as executor:
#         results = list(executor.map(lambda read_id: process_read(read_id, blast_results), read_ids[0]))

#     # Filter out None results
#     results = [result for result in results if result is not None]

#     # Write the results to the output file
#     with open(output_file, 'w') as f:
#         for result in results:
#             f.write(result + '\n')

#     print("Processing complete. Results saved to", output_file)

# if __name__ == "__main__":
#     parser = argparse.ArgumentParser(description="Process read IDs and extract best hits from BLAST results.")
#     parser.add_argument('-i', '--input', required=True, help="Input file with read IDs")
#     parser.add_argument('-o', '--output', required=True, help="Output file for results")
#     parser.add_argument('-b', '--blast', required=True, help="BLAST results file")
#     parser.add_argument('-w', '--workers', type=int, default=80, help="Number of worker processes")

#     args = parser.parse_args()
#     main(args.input, args.output, args.blast, args.workers)
