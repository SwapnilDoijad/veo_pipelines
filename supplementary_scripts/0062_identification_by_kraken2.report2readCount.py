#!/usr/bin/env python3

import argparse
import re
from collections import defaultdict

parser = argparse.ArgumentParser(
    description="Extract family/genus/species read counts from Kraken2 report"
)

parser.add_argument("-i", "--input", required=True, help="Kraken2 report file")
parser.add_argument("-o", "--output", required=True, help="Output TSV")
parser.add_argument(
    "-l", "--level",
    choices=["F", "G", "S"],
    required=True,
    help="Rank level: F=family, G=genus, S=species"
)
parser.add_argument(
    "--use-clade-reads",
    action="store_true",
    help="Use clade reads instead of direct reads"
)
parser.add_argument(
    "--min-reads",
    type=int,
    default=1,
    help="Minimum reads to report"
)
parser.add_argument(
    "--collapse-special",
    action="store_true",
    help="Collapse uncultured/metagenome/environmental/source-like species names"
)

args = parser.parse_args()

special_patterns = {
    "uncultured": re.compile(
        r"uncultured|unidentified|unknown|bacterium|archaeon",
        re.IGNORECASE,
    ),
    "metagenome": re.compile(
        r"metagenome|environmental sample|environmental clone",
        re.IGNORECASE,
    ),
    "environmental_source": re.compile(
        r"manure|sludge|wastewater|sewage|soil|sediment|compost|rumen|gut|feces|faeces|stool|biofilm|activated sludge",
        re.IGNORECASE,
    ),
    "phage": re.compile(
        r"\bphage\b",
        re.IGNORECASE,
    ),
}

counts = defaultdict(int)
taxids = {}

with open(args.input) as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")

        if len(parts) < 6:
            continue

        perc = parts[0].strip()
        clade_reads = int(parts[1].strip())
        direct_reads = int(parts[2].strip())
        rank = parts[3].strip()
        taxid = parts[4].strip()
        name = parts[5].strip()

        if rank != args.level:
            continue

        reads = clade_reads if args.use_clade_reads else direct_reads

        if reads < args.min_reads:
            continue

        final_name = name

        if args.collapse_special:
            for category, pattern in special_patterns.items():
                if pattern.search(name):
                    final_name = category
                    taxid = category
                    break

        counts[final_name] += reads
        taxids[final_name] = taxid

with open(args.output, "w") as out:
    out.write("name\ttaxid\treads\tlevel\n")

    for name, reads in sorted(counts.items(), key=lambda x: x[1], reverse=True):
        out.write(f"{name}\t{taxids[name]}\t{reads}\t{args.level}\n")

print(f"Written: {args.output}")
print(f"Entries: {len(counts)}")