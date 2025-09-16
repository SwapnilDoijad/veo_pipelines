#!/usr/bin/env python3

import argparse
import csv
import gzip
import io
import os
import re
import sys
from typing import Dict, Iterable, List, Tuple

KEYWORDS = [
    r"\btransposase\b",
    r"\bintegrase\b",
    r"\bresolvase\b",
    r"\brecombinase\b",
    r"\bexcisionase\b",
]

# Common synonyms/aliases that often appear in annotations (optional; enabled with --include-synonyms)
SYNONYMS = [
    r"\bxis\b",                      # excisionase in phages
    r"\bRDF\b",                      # recombination directionality factor (excision helper)
    r"\bsite[- ]specific recombinase\b",
    r"\bserine recombinase\b",
    r"\btyrosine recombinase\b",
    r"\bIntI\d?\b",                  # integron integrase names
    r"\bintegron integrase\b",
]

ATTR_PRIORITY = ["product", "gene", "Name", "note", "Note", "Dbxref", "ID"]

def open_possibly_gz(path: str):
    if path.endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf-8", errors="replace")
    return open(path, "rt", encoding="utf-8", errors="replace")

def parse_attributes(attr_field: str) -> Dict[str, str]:
    attrs: Dict[str, str] = {}
    for part in attr_field.strip().split(";"):
        if not part:
            continue
        if "=" in part:
            k, v = part.split("=", 1)
        elif " " in part and not part.strip().startswith(("Dbxref","dbxref")):
            # handle space-separated key value (rare)
            k, v = part.split(" ", 1)
        else:
            # unkeyed attribute; collect under "misc"
            k, v = "misc", part
        # decode % encodings and replace commas with pipes for readability
        v = v.replace(",", "|")
        try:
            v = re.sub(r"%([0-9A-Fa-f]{2})", lambda m: bytes.fromhex(m.group(1)).decode('utf-8','replace'), v)
        except Exception:
            pass
        attrs[k] = v
    return attrs

def match_any(text: str, patterns: List[str]) -> Tuple[str, str]:
    """Return (matched_keyword, matched_text) or ('','') if none."""
    for pat in patterns:
        m = re.search(pat, text, flags=re.IGNORECASE)
        if m:
            return (pat.strip(r"\b"), m.group(0))
    return ("", "")

def scan_gff(
    gff_path: str,
    out_tsv: str,
    include_synonyms: bool = False,
    feature_filter: Iterable[str] = ()
) -> int:
    patterns = KEYWORDS + (SYNONYMS if include_synonyms else [])
    total_hits = 0
    with open_possibly_gz(gff_path) as fh, open(out_tsv, "w", newline="", encoding="utf-8") as out:
        w = csv.writer(out, delimiter="\t")
        w.writerow([
            "seqid","start","end","strand","type",
            "matched_pattern","matched_string","attribute_field",
            "ID","Name","gene","product","note","Dbxref","raw_attributes"
        ])
        for line in fh:
            if not line or line.startswith("#"):
                continue
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9:
                continue
            seqid, source, ftype, start, end, score, strand, phase, attr = cols[:9]
            if feature_filter and ftype not in feature_filter:
                # keep CDS/gene by default if filter is provided
                pass
            attrs = parse_attributes(attr)
            # Build a combined searchable string from prioritized attributes
            searchable_fields = []
            for key in ATTR_PRIORITY:
                if key in attrs:
                    searchable_fields.append(f"{key}:{attrs[key]}")
            if not searchable_fields:
                searchable_fields.append(attr)
            combined = " | ".join(searchable_fields)
            matched_pat, matched_str = match_any(combined, patterns)
            if matched_pat:
                total_hits += 1
                w.writerow([
                    seqid, start, end, strand, ftype,
                    matched_pat, matched_str,
                    next((k for k in ATTR_PRIORITY if k in attrs), ""),
                    attrs.get("ID",""),
                    attrs.get("Name",""),
                    attrs.get("gene",""),
                    attrs.get("product",""),
                    attrs.get("note", attrs.get("Note","")),
                    attrs.get("Dbxref",""),
                    attr
                ])
    return total_hits

def main():
    p = argparse.ArgumentParser(
        description="Scan a GFF/GFF3 for mobile-DNA related genes: transposase, integrase, resolvase, recombinase, excisionase."
    )
    # accept input GFF via -i/--gff (positional argument removed)
    p.add_argument("-i", "--gff", dest="gff", required=True, help="Input GFF/GFF3 file (optionally .gz)")
    p.add_argument("-o","--out", default=None, help="Output TSV (default: <gff>.mge_hits.tsv)")
    p.add_argument("--include-synonyms", action="store_true",
                   help="Also search common aliases (xis, RDF, IntI, 'serine/tyrosine recombinase', etc.)")
    p.add_argument("--only-cds", action="store_true",
                   help="Restrict to CDS features only (skip other types).")
    args = p.parse_args()

    gff_path = args.gff
    out_tsv = args.out or (gff_path + ".mge_hits.tsv")
    feature_filter = ("CDS",) if args.only_cds else tuple()
    hits = scan_gff(gff_path, out_tsv, include_synonyms=args.include_synonyms, feature_filter=feature_filter)
    sys.stderr.write(f"[scan_mge_gff] wrote {out_tsv} with {hits} hits\n")

if __name__ == "__main__":
    main()
