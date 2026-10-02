#!/usr/bin/env python3

import argparse
import re
import sys
from pathlib import Path
from typing import List
from Bio import SeqIO


def sanitize_filename(sequence_id: str) -> str:
    """
    Replace characters that may be problematic in filenames.
    """
    return re.sub(r"[^A-Za-z0-9._-]", "_", sequence_id)


def read_ids(id_file: Path) -> List[str]:
    """
    Read IDs from a file.

    The first whitespace-separated field from each non-empty line is used.
    Blank lines and lines beginning with '#' are ignored.
    """
    ids = []

    with id_file.open("r") as handle:
        for line_number, line in enumerate(handle, start=1):
            line = line.strip()

            if not line or line.startswith("#"):
                continue

            sequence_id = line.split()[0]

            if sequence_id.lower() in {"id", "sequence_id", "seqid"}:
                continue

            ids.append(sequence_id)

    # Remove duplicates while preserving input order
    return list(dict.fromkeys(ids))


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Extract sequences listed in an ID file from a multifasta file "
            "and save each sequence as an individual FASTA file."
        )
    )

    parser.add_argument(
        "-id",
        "--ids",
        required=True,
        type=Path,
        help="File containing sequence IDs, one ID per line.",
    )

    parser.add_argument(
        "-f",
        "--fasta",
        required=True,
        type=Path,
        help="Input multifasta file.",
    )

    parser.add_argument(
        "-o",
        "--output",
        required=True,
        type=Path,
        help="Output directory for individual FASTA files.",
    )

    parser.add_argument(
        "--extension",
        default="fna",
        choices=["fna", "fa", "fasta"],
        help="Extension for output files. Default: fna",
    )

    args = parser.parse_args()

    if not args.ids.is_file():
        sys.exit(f"ERROR: ID file does not exist: {args.ids}")

    if not args.fasta.is_file():
        sys.exit(f"ERROR: FASTA file does not exist: {args.fasta}")

    requested_ids = read_ids(args.ids)

    if not requested_ids:
        sys.exit(f"ERROR: No sequence IDs were found in: {args.ids}")

    args.output.mkdir(parents=True, exist_ok=True)

    requested_set = set(requested_ids)
    found_ids = set()
    written = 0

    for record in SeqIO.parse(args.fasta, "fasta"):
        # Biopython record.id is the first whitespace-separated field
        # in the FASTA header.
        sequence_id = record.id

        if sequence_id not in requested_set:
            continue

        output_name = sanitize_filename(sequence_id)
        output_file = args.output / f"{output_name}.{args.extension}"

        SeqIO.write(record, output_file, "fasta")

        found_ids.add(sequence_id)
        written += 1

    missing_ids = [seq_id for seq_id in requested_ids if seq_id not in found_ids]

    print(f"Requested IDs : {len(requested_ids)}")
    print(f"Sequences found: {len(found_ids)}")
    print(f"Files written  : {written}")
    print(f"Output folder  : {args.output}")

    if missing_ids:
        missing_file = args.output / "missing_ids.txt"

        with missing_file.open("w") as handle:
            handle.write("\n".join(missing_ids) + "\n")

        print(f"Missing IDs    : {len(missing_ids)}")
        print(f"Missing-ID list: {missing_file}", file=sys.stderr)

        # Return a nonzero status to indicate that some IDs were missing.
        sys.exit(1)


if __name__ == "__main__":
    main()