#!/usr/bin/env python3
"""
Count bases in a FASTQ (gzipped) file.

Usage:
  python3 count_bases_fastq.py sample.fastq.gz

Outputs two numbers to stdout in a human-friendly form:
  reads: <N>
  bases: <M>

This parser handles sequence lines wrapped across multiple lines by
accumulating sequence lines between a header (starting with '@') and
the '+' separator line, then consuming corresponding quality characters
after the '+' until their length equals the sequence length.

Exit codes:
  0 - success
  2 - usage error / file not found
  3 - parse error (malformed FASTQ)
"""

import argparse
import gzip
import io
import os
import sys


def open_maybe_gz(path):
    """
    Open a path or stdin ('-') and return a text-mode file-like object.
    If the stream/file is gzipped (magic 1f 8b) it will be transparently
    decompressed.
    """
    if path == '-':
        # Use sys.stdin.buffer to access raw bytes and try to peek the magic
        buf = sys.stdin.buffer
        try:
            head = buf.peek(2)[:2]
        except Exception:
            # Fallback: read a small chunk and wrap it back
            data = buf.read()
            buf = io.BytesIO(data)
            head = data[:2]

        if head == b"\x1f\x8b":
            gz = gzip.GzipFile(fileobj=buf, mode='rb')
            return io.TextIOWrapper(gz, encoding='utf-8', errors='replace')
        return io.TextIOWrapper(buf, encoding='utf-8', errors='replace')

    # filesystem path
    if not os.path.exists(path):
        raise FileNotFoundError(path)
    with open(path, 'rb') as fh:
        head = fh.read(2)
    if head == b"\x1f\x8b":
        return gzip.open(path, 'rt', encoding='utf-8', errors='replace')
    return open(path, 'rt', encoding='utf-8', errors='replace')


def count_bases_and_reads(fp):
    total_bases = 0
    total_reads = 0

    line = fp.readline()
    while line:
        if not line.startswith('@'):
            # skip blank lines
            if line.strip() == '':
                line = fp.readline()
                continue
            raise ValueError(f"Expected header starting with '@', got: {line!r}")

        # header found
        total_reads += 1

        # accumulate sequence lines until a line that starts with '+'
        seq_lines = []
        while True:
            next_line = fp.readline()
            if not next_line:
                raise ValueError('Unexpected end of file while reading sequence')
            if next_line.startswith('+'):
                break
            seq_lines.append(next_line.rstrip('\n'))

        seq = ''.join(seq_lines)
        seq_len = len(seq)
        total_bases += seq_len

        # now read quality lines until we've collected seq_len quality chars
        qual_collected = 0
        while qual_collected < seq_len:
            qline = fp.readline()
            if not qline:
                raise ValueError('Unexpected end of file while reading quality')
            qual_collected += len(qline.rstrip('\n'))

        # move to next record
        line = fp.readline()

    return total_reads, total_bases


def main(argv=None):
    parser = argparse.ArgumentParser(description='Count bases in a FASTQ(.gz) file')
    parser.add_argument('-i', '--input', required=True,
                        help="Path to FASTQ or FASTQ.GZ file (use '-' for stdin)")
    args = parser.parse_args(argv)
    inp = args.input

    try:
        with open_maybe_gz(inp) as fp:
            reads, bases = count_bases_and_reads(fp)
    except FileNotFoundError:
        print(f'File not found: {inp}', file=sys.stderr)
        return 2
    except ValueError as e:
        print(f'Parse error: {e}', file=sys.stderr)
        return 3
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        return 3

    # Derive a concise file id to print.
    if inp == '-':
        file_id = 'stdin'
    else:
        file_id = os.path.basename(inp)
        # strip common compression suffix
        if file_id.endswith('.gz'):
            file_id = file_id[:-3]
        # strip common FASTQ extensions
        for ext in ('.fastq', '.fq'):
            if file_id.endswith(ext):
                file_id = file_id[:-len(ext)]
                break

    # Print exactly three fields (tab-separated): file_id, reads, bases
    # This makes the output easy to parse in downstream pipelines.
    print(f"{file_id}\t{reads}\t{bases}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
