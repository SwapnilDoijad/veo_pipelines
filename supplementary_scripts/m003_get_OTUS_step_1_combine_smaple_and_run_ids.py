import concurrent.futures
import os

def process_run_id(sample_id, run_id):
    with open('tmp/step_1/sample_ids_run_ids.txt', 'a') as sample_ids_run_ids_file:
        sample_ids_run_ids_file.write(f"{sample_id} {run_id}\n")

    with open('tmp/step_1/run_ids.txt', 'a') as run_ids_file:
        run_ids_file.write(f"{run_id}\n")

def process_sample(sample_id):
    run_ids_file_path = f'tmp/step_1/run_ids_for_sample/list.run_ids_for_sample_{sample_id}.txt'

    if os.path.exists(run_ids_file_path):
        with open(run_ids_file_path, 'r') as run_ids_file:
            run_ids = run_ids_file.read().splitlines()

        with concurrent.futures.ThreadPoolExecutor() as executor:
            executor.map(lambda run_id: process_run_id(sample_id, run_id), run_ids)

if __name__ == "__main__":
    sample_id_list_path = "list.all_samples_unique.txt"  # Replace with the actual path

    with open(sample_id_list_path, 'r') as file:
        sample_ids = file.read().split()

    with concurrent.futures.ThreadPoolExecutor() as executor:
        executor.map(process_sample, sample_ids)
