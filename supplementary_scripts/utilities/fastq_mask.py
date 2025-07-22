import argparse
from Bio import SeqIO

def mask_low_quality_bases(record, threshold):
    masked_seq = ''.join(
        base if qual >= threshold else 'N'
        for base, qual in zip(str(record.seq), record.letter_annotations["phred_quality"])
    )
    record.seq = record.seq.__class__(masked_seq)
    return record

def main():
    parser = argparse.ArgumentParser(description="Mask reads in FASTQ by quality")
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ file")
    parser.add_argument("-o", "--output", required=True, help="Output FASTQ file")
    parser.add_argument("-q", "--quality", type=int, required=True, help="Quality score threshold")
    args = parser.parse_args()

    with open(args.output, "w") as out_handle:
        for record in SeqIO.parse(args.input, "fastq"):
            masked_record = mask_low_quality_bases(record, args.quality)
            SeqIO.write(masked_record, out_handle, "fastq")

if __name__ == "__main__":
    main()
