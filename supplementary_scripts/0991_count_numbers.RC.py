import argparse
import multiprocessing

def process_read(read_id, input_file, output_file):
    best_hit = None
    mismatches = []
    
    with open(input_file, 'r') as infile:
        for line in infile:
            fields = line.strip().split('\t')
            if fields[0] == read_id:
                if best_hit is None or int(fields[5]) < best_hit[1]:
                    best_hit = (fields[0], fields[1], int(fields[5]))
                mismatches.append(fields[5])
    
    if best_hit is not None:
        with open(output_file, 'a') as outfile:
            outfile.write("{}\t{}\t{}\n".format(best_hit[0], best_hit[1], '\t'.join(mismatches)))

def main(input_file, output_file, read_ids_file):
    with open(read_ids_file, 'r') as read_ids:
        read_id_list = [line.strip().replace('@', '') for line in read_ids]
    
    # Create a pool of worker processes
    num_cpus = 80
    pool = multiprocessing.Pool(processes=num_cpus)
    
    # Map the process_read function to read IDs for parallel processing
    pool.starmap(process_read, [(read_id, input_file, output_file) for read_id in read_id_list])
    
    # Close the pool to release resources
    pool.close()
    pool.join()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process read IDs and extract information.")
    parser.add_argument("-i", "--input_file", required=True, help="Input TSV file")
    parser.add_argument("-o", "--output_file", required=True, help="Output TSV file")
    parser.add_argument("-r", "--read_ids_file", required=True, help="File containing read IDs")
    args = parser.parse_args()
    
    main(args.input_file, args.output_file, args.read_ids_file)
