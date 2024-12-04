import os
import multiprocessing
import subprocess
from glob import glob

def process_run_id(run_id):
    input_pattern = f'tmp/step_3/OTU_files/raw_files/{run_id}_*.tsv'
    output_file = f'tmp/step_4/OTU_files/{run_id}_OTUs.tsv'
    output_file_2 = f'tmp/step_4/OTU_files/{run_id}_OTUs.2.tsv'

    input_files = glob(input_pattern)

    if input_files:
        if not os.path.isfile(output_file_2):
            print(f"Processing {run_id}")
            subprocess.run([
                'python3',
                '/home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUs_step_4.py',
                '-i', *input_files,  # Unpack the list of input files
                '-o', output_file
            ], check=True)

            subprocess.run(['awk', '{print $2}', output_file], stdout=open(output_file_2, 'w'), check=True)
        else:
            print(f"{run_id} already finished")
    else:
        print(f"No input files found for {run_id}")

if __name__ == "__main__":
    # Replace with the actual path to your unique run IDs file
    run_ids_file_path = "tmp/step_4/list.run_id_unique_biom.sort_uniq.txt"

    with open(run_ids_file_path, 'r') as file:
        run_ids = file.read().split()

    with multiprocessing.Pool() as pool:
        pool.map(process_run_id, run_ids)
