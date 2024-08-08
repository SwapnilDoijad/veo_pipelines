import multiprocessing
import shutil
import os

def copy_and_cat(otu_file):
    destination_path = 'tmp/step_3/OTU_files/raw_files/'
    all_tsv_path = 'tmp/step_3/OTU_files/all.tsv'

    # Copy to the destination folder
    shutil.copy(otu_file, destination_path)

    # Append content to all.tsv
    with open(all_tsv_path, 'a') as all_tsv_file:
        with open(otu_file, 'r') as otu_file_content:
            all_tsv_file.write(otu_file_content.read())

if __name__ == "__main__":
    # Replace with the actual path to your unique OTU files list
    otu_files_list_path = "tmp/step_2/list.run_id_unique_biom_path.txt"

    with open(otu_files_list_path, 'r') as file:
        otu_files = file.read().split()

    with multiprocessing.Pool() as pool:
        pool.map(copy_and_cat, otu_files)
