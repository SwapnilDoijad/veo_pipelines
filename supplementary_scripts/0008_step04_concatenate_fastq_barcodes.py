import os
import glob
import multiprocessing

def process_file(i, base_path):
    print(f"Processing file: {i}")
    try:
        barcode_list_path = os.path.join(base_path, 'tmp', 'lists', 'list.barcodes.txt')
        with open(barcode_list_path) as barcode_list_file:
            for barcode in barcode_list_file:
                barcode = barcode.strip()
                input_file_pattern = os.path.join(base_path, 'demultiplexed_files', f'{i}', barcode, '*.fastq')
                matching_files = glob.glob(input_file_pattern)
                if matching_files:
                    output_file_path = os.path.join(base_path, 'demultiplexed_files_barcoded_byPythonScript', f'{barcode}.fastq')
                    with open(output_file_path, 'w') as output_file:
                        for input_file in matching_files:
                            with open(input_file, 'r') as barcode_file:
                                output_file.write(barcode_file.read())
    except Exception as e:
        print(f"An error occurred for file {i}: {e}")

if __name__ == '__main__':
    base_path = 'results/0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu'  
    file_list = os.listdir(os.path.join(base_path, 'demultiplexed_files'))

    num_cpus = 80  # Number of CPUs you have
    pool = multiprocessing.Pool(processes=num_cpus)

    try:
        # Use the map function to parallelize processing across files
        pool.starmap(process_file, [(i, base_path) for i in file_list])

    except Exception as e:
        print(f"An error occurred in the main process: {e}")

    finally:
        pool.close()
        pool.join()
