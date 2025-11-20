#!/usr/bin/env python3
"""
Concatenate multiple aligned FASTA files by sequence header (ID).

Behavior:
- For each input alignment file (in the order given), record the length L_i of the alignment.
- For each sequence header (ID) seen across all files, build a concatenated sequence by:
    - appending the sequence from file i if present (must be length L_i unless --no-check),
    - otherwise appending gap characters of length L_i.
- Output FASTA uses a header chosen as:
    - by default: the first token of the header line (ID) as >ID
    - if --full-header: the first full header line encountered for that ID is preserved (without the leading '>').
Options:
  -o/--out: output file (default stdout)
  --full-header: keep full header when writing output and when matching (match uses full header)
  --no-check: skip verifying that sequences in a file all have the same length
  --id-field N: use the Nth whitespace-separated token as ID (1-based; default 1)
  --pad-char: character for padding missing sequences (default '-')
"""

import argparse
import sys
import os
from collections import OrderedDict, defaultdict

DEFAULT_EXTS = ('.fas', '.fasta', '.fa', '.aln')

def parse_fasta(path, id_field=1, use_full_header=False):
    """
    Parse fasta file into dict: id -> sequence (no line breaks).
    Also returns the dict of id -> full header (first seen).
    """
    seqs = OrderedDict()
    full_headers = {}
    cur_id = None
    cur_header = None
    cur_seq_parts = []
    def finish():
        if cur_id is not None:
            seqs[cur_id] = ''.join(cur_seq_parts)
            if cur_id not in full_headers:
                full_headers[cur_id] = cur_header

    with open(path, 'r') as fh:
        for line in fh:
            line = line.rstrip('\n')
            if not line:
                continue
            if line.startswith('>'):
                # finish previous
                if cur_id is not None:
                    seqs[cur_id] = ''.join(cur_seq_parts)
                    if cur_id not in full_headers:
                        full_headers[cur_id] = cur_header
                cur_header = line[1:].strip()
                if use_full_header:
                    cur_id = cur_header
                else:
                    parts = cur_header.split()
                    if len(parts) < id_field:
                        cur_id = parts[0] if parts else cur_header
                    else:
                        cur_id = parts[id_field-1]
                cur_seq_parts = []
            else:
                cur_seq_parts.append(line.strip())
        # final
        if cur_header is not None:
            seqs[cur_id] = ''.join(cur_seq_parts)
            if cur_id not in full_headers:
                full_headers[cur_id] = cur_header
    return seqs, full_headers

def main():
    p = argparse.ArgumentParser(description="Concatenate aligned FASTA files by header/ID.")
    p.add_argument('files', nargs='+', help='Aligned FASTA files in order to concatenate')
    p.add_argument('-o','--out', default=None, help='Output FASTA file (default stdout)')
    p.add_argument('--full-header', action='store_true', help='Match and keep full header lines instead of first token')
    p.add_argument('--no-check', action='store_true', help='Do NOT check that sequences in each file have consistent length; uses first seq length as file length')
    p.add_argument('--id-field', type=int, default=1, help='If not --full-header, which whitespace token to use as ID (1-based). Default 1')
    p.add_argument('--pad-char', default='-', help='Character to use for padding missing sequences (default "-")')
    args = p.parse_args()

    # expand inputs: allow directories or files (directories will be scanned for .fas/.fa/.fasta/.aln)
    raw_inputs = args.files
    files = []
    for inp in raw_inputs:
        if os.path.isdir(inp):
            found = [os.path.join(inp, n) for n in sorted(os.listdir(inp)) if os.path.splitext(n)[1].lower() in DEFAULT_EXTS]
            if not found:
                print(f"Warning: directory '{inp}' contained no alignment files with extensions {DEFAULT_EXTS}", file=sys.stderr)
            else:
                files.extend(found)
        else:
            files.append(inp)

    if not files:
        print("ERROR: no input alignment files found/expanded from provided inputs.", file=sys.stderr)
        sys.exit(2)

    id_field = args.id_field
    use_full_header = args.full_header
    pad_char = args.pad_char

    # Read all files
    per_file_seqs = []
    per_file_headers = []
    file_lengths = []
    all_ids = []
    all_id_set = set()

    for f in files:
        seqs, headers = parse_fasta(f, id_field=id_field, use_full_header=use_full_header)
        per_file_seqs.append(seqs)
        per_file_headers.append(headers)
        # determine alignment length for this file
        if len(seqs) == 0:
            print(f"Warning: file '{f}' has no sequences.", file=sys.stderr)
            file_lengths.append(0)
        else:
            seq_lengths = {len(s) for s in seqs.values()}
            if len(seq_lengths) > 1 and not args.no_check:
                print(f"ERROR: file '{f}' contains sequences of differing lengths ({sorted(seq_lengths)}). Use --no-check to bypass.", file=sys.stderr)
                sys.exit(2)
            # choose the first sequence length as file length
            L = next(iter(seq_lengths)) if seq_lengths else 0
            file_lengths.append(L)
        # collect ids
        for id_ in seqs.keys():
            if id_ not in all_id_set:
                all_ids.append(id_)
                all_id_set.add(id_)

    # Also include any IDs present only in other files (we already collected above).
    # Build output headers mapping: if not full-header, prefer the first full header encountered for each id
    out_full_headers = {}
    for headers in per_file_headers:
        for id_, full in headers.items():
            if id_ not in out_full_headers:
                out_full_headers[id_] = full

    # Now, for each ID in union, build concatenation
    concatenated = OrderedDict()
    for id_ in all_ids:
        parts = []
        for idx, seqs in enumerate(per_file_seqs):
            L = file_lengths[idx]
            if L == 0:
                # nothing in that file (no sequences); append nothing
                continue
            seq = seqs.get(id_)
            if seq is None:
                parts.append(pad_char * L)
            else:
                if len(seq) != L and not args.no_check:
                    print(f"ERROR: sequence for ID '{id_}' in file '{files[idx]}' has length {len(seq)} but expected {L}. Use --no-check to bypass.", file=sys.stderr)
                    sys.exit(3)
                # if len differs and --no-check, pad/truncate to L
                if len(seq) != L and args.no_check:
                    if len(seq) < L:
                        seq = seq + pad_char * (L - len(seq))
                    else:
                        seq = seq[:L]
                parts.append(seq)
        concatenated[id_] = ''.join(parts)

    # Write output
    outfh = open(args.out, 'w') if args.out else sys.stdout
    for id_, seq in concatenated.items():
        if use_full_header:
            header = out_full_headers.get(id_, id_)
            outfh.write(f">{header}\n")
        else:
            # write ID as header (first token), but if we have a full header mapping, preserve it as description
            full = out_full_headers.get(id_)
            if full:
                # ensure we don't duplicate id if it's already the first token of full
                parts = full.split()
                if parts and parts[0] == id_:
                    header = full
                else:
                    header = id_ + " " + full
            else:
                header = id_
            outfh.write(f">{header}\n")
        # wrap sequence at 80 chars
        for i in range(0, len(seq), 80):
            outfh.write(seq[i:i+80] + "\n")
    if args.out:
        outfh.close()

if __name__ == '__main__':
    main()