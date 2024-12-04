import argparse
from multiprocessing import Pool, cpu_count

def search_sequence_in_record(record, search_sequence, upstream_bases):
    current_header, current_sequence = record
    results = []
    index = current_sequence.find(search_sequence)
    if index != -1:
        start = max(0, index - upstream_bases)
        end = index + len(search_sequence)
        result = current_header + "\n" + current_sequence[start:end]
        results.append(result)
    return results

def search_fasta(fasta_file, search_sequence, upstream_bases):
    results = []

    with open(fasta_file, "r") as f:
        current_record = ("", "")
        records = []
        for line in f:
            if line.startswith(">"):
                if current_record[0] and current_record[1]:
                    records.append(current_record)
                current_record = (line.strip(), "")
            else:
                current_record = (current_record[0], current_record[1] + line.strip())
        if current_record[0] and current_record[1]:
            records.append(current_record)

    with Pool(cpu_count()) as pool:
        results = pool.starmap(search_sequence_in_record, [(record, search_sequence, upstream_bases) for record in records])

    return [result for sublist in results for result in sublist]

def main():
    parser = argparse.ArgumentParser(description="Search for a sequence in a multi-FASTA file using multiple CPUs and extract sequences with specified upstream bases before the match.")
    parser.add_argument("-i", "--input_sequence", required=True, help="Input search sequence")
    parser.add_argument("-f", "--fasta_file", required=True, help="Input multi-FASTA file")
    parser.add_argument("-o", "--output_file", required=True, help="Output file to write the results")
    parser.add_argument("-u", "--upstream_bases", type=int, help="Number of upstream bases before the match (default: 35)")
    args = parser.parse_args()

    search_sequence = args.input_sequence
    fasta_file = args.fasta_file
    output_file = args.output_file
    upstream_bases = args.upstream_bases

    results = search_fasta(fasta_file, search_sequence, upstream_bases)

    if results:
        with open(output_file, "w") as out:
            out.write("\n".join(results))
    else:
        print("Sequence not found in the FASTA file.")

if __name__ == "__main__":
    main()
