import multiprocessing
import os

def process_sample(sample_id):
    print(f"getting run_ids for sample {sample_id}")

    with open('/work/groups/VEO/databases/mgnify/mgnify_all_ids_combined.20230127.tab', 'r') as mgnify_file:
        lines = mgnify_file.readlines()

        for line in lines:
            if sample_id in line:
                study_id = line.split()[2]
                run_ids = line.split()[1].replace('_', ' ').replace('null', '').split()

                output_file_path = f'tmp/step_1/run_ids_for_sample/list.run_ids_for_sample_{sample_id}.txt'
                with open(output_file_path, 'w') as output_file:
                    output_file.write('\n'.join(run_ids))
                break

if __name__ == "__main__":
    sample_id_list_path = "list.all_samples_unique.txt"

    with open(sample_id_list_path, 'r') as file:
        sample_ids = file.read().split()

    # Adjust the number of workers based on your system capabilities
    num_workers = 80

    with multiprocessing.Pool(processes=num_workers) as pool:
        pool.map(process_sample, sample_ids)
