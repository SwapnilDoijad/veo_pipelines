import os
from multiprocessing import Pool

def process_run_id(run_id):
    try:
        # Ensure directory exists
        os.makedirs('tmp/step_5', exist_ok=True)

        # Your existing loop body
        with open(f'tmp/step_4/OTU_files/{run_id}_taxonomy.2.tsv', 'r') as infile:
            lines = infile.readlines()
        with open(f'tmp/step_5/{run_id}_taxonomy.tmp', 'w') as outfile:
            outfile.write(f'{run_id}\n')
            outfile.writelines(lines[1:])

        with open('tmp/step_5/all.for_OTU_taxa.2.tsv.tmp', 'r') as infile1, \
             open(f'tmp/step_5/{run_id}_taxonomy.tmp', 'r') as infile2:
            data1 = infile1.readlines()
            data2 = infile2.readlines()

        with open(f'tmp/step_5/{run_id}_taxonomy.tmp.2', 'w') as outfile:
            for line1, line2 in zip(data1, data2):
                outfile.write(f'{line1.rstrip()}\t{line2}')

        os.rename(f'tmp/step_5/{run_id}_taxonomy.tmp.2', 'tmp/step_5/all.for_OTU_taxa.2.tsv.tmp')
        os.remove(f'tmp/step_5/{run_id}_taxonomy.tmp')

    except FileNotFoundError as e:
        print(f"Error processing {run_id}: {e}")

if __name__ == "__main__":
    # Read run_ids from the file
    with open('tmp/step_2/list.run_id_unique_biom.txt', 'r') as run_id_file:
        run_ids = run_id_file.read().splitlines()

    # Use multiprocessing Pool for parallel processing
    with Pool(processes=80) as pool:
        pool.map(process_run_id, run_ids)
