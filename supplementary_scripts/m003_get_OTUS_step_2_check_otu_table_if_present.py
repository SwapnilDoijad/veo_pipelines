import multiprocessing
import os

def get_OTUs_table_path(run_id):
    OTUs_table_path = None

    # Replace with the actual path to your OTUs table file
    OTUs_table_file = "/work/groups/VEO/databases/mgnify/mgnify_all_OTUs_table_available.20240201.tab"

    with open(OTUs_table_file, 'r') as file:
        for line in file:
            if run_id in line:
                OTUs_table_path = line.strip()
                break

    return OTUs_table_path

def process_run_id(run_id):
    OTUs_table_path = get_OTUs_table_path(run_id)

    if not OTUs_table_path:
        with open('tmp/step_2/list.OTUs_table_absent.txt', 'a') as absent_file:
            absent_file.write(f"{run_id}\n")
    else:
        with open('tmp/step_2/list.OTUs_table_present_and_their_path.txt', 'a') as present_file:
            present_file.write(f"{OTUs_table_path}\n")

if __name__ == "__main__":
    # Replace with the actual path to your unique run IDs file
    run_ids_file_path = "tmp/step_1/run_ids_unique.txt"

    with open(run_ids_file_path, 'r') as file:
        run_ids = file.read().split()

    with multiprocessing.Pool() as pool:
        pool.map(process_run_id, run_ids)
