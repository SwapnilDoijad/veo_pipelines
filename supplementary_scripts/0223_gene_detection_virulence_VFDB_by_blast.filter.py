#!/usr/bin/env python3
import argparse, sys, re
import pandas as pd
import numpy as np

EXPECTED = ["sseqid","qseqid","sstart","send","qstart","qend","slen","qlen",
            "evalue","bitscore","length","mismatch","gaps","pident","qcovs",
            "total-query-coverage","gene","protein","group","originated-from"]
NUMERIC = ["qstart","qend","slen","evalue","bitscore","length","pident"]

def read_table(p):
    df = pd.read_csv(p, sep="\t", dtype=str)
    if not set(EXPECTED).issubset(df.columns) and df.shape[1] == len(EXPECTED):
        df.columns = EXPECTED
    need = ["qseqid","qstart","qend","evalue","bitscore","length","slen","pident"]
    miss = [c for c in need if c not in df.columns]
    if miss: sys.exit("ERROR missing cols: "+", ".join(miss))
    for c in NUMERIC: df[c] = pd.to_numeric(df[c], errors="coerce")
    return df

def add_scovs(df):
    sc = 100.0 * (df["length"] / df["slen"])
    df["scovs"] = np.clip(sc.fillna(0), None, 100)
    return df

def norm_text(s):
    # normalize labels like "RcsAB_(CVF856)_" vs "RcsAB_(CVF856)"
    return re.sub(r"\s+", " ", str(s)).strip(" _")

def add_loci(df, gap):
    # normalize query coords and sweep left->right to assign locus ids
    df = df.copy()
    df["qlo"] = df[["qstart","qend"]].min(axis=1)
    df["qhi"] = df[["qstart","qend"]].max(axis=1)
    df.sort_values(by=["qseqid","qlo","evalue","bitscore","pident","scovs"],
                   ascending=[True, True, True, False, False, False],
                   kind="mergesort", inplace=True)
    locus_ids = []
    last = {}
    for i,row in df.iterrows():
        key = row["qseqid"]
        qlo, qhi = row["qlo"], row["qhi"]
        if key not in last or qlo > last[key]["end"] + gap:
            last[key] = {"end": qhi, "locus": last.get(key,{}).get("locus",0)+1}
        else:
            last[key]["end"] = max(last[key]["end"], qhi)
        locus_ids.append(last[key]["locus"])
    df["locus_id"] = locus_ids
    return df

def best_by(df, keys):
    order = keys + ["evalue","bitscore","pident","scovs"]
    asc   = [True]*len(keys) + [True, False, False, False]
    ranked = df.sort_values(order, ascending=asc, kind="mergesort")
    return ranked.drop_duplicates(subset=keys, keep="first")

def main():
    ap = argparse.ArgumentParser(description="Collapse BLAST hits by locus with subject coverage.")
    ap.add_argument("-i","--input", required=True)
    ap.add_argument("-o","--output", required=True)
    ap.add_argument("--mode", choices=[
        "query",                # best per qseqid
        "query-entity",         # best per (qseqid, ENTITY)
        "query-locus",          # best per (qseqid, locus)
        "query-entity-locus"    # best per (qseqid, ENTITY, locus)
    ], default="query-entity-locus")
    ap.add_argument("--entity", default="gene",
                    help="Column(s) to define the gene/entity label; comma-separated. "
                         "Examples: gene | group | sseqid | gene,group")
    ap.add_argument("--normalize_entity", action="store_true",
                    help="Strip underscores/whitespace on entity columns before grouping.")
    ap.add_argument("--gap", type=int, default=0, help="bp separation for a new locus (query-side).")
    ap.add_argument("--min-pident", type=float)
    ap.add_argument("--min-scovs", type=float)
    ap.add_argument("--min-length", type=float)
    ap.add_argument("--max-evalue", type=float)
    args = ap.parse_args()

    df = read_table(args.input)
    original_cols = list(df.columns)
    df = add_scovs(df)

    # entity columns (can be empty for pure-locus collapse)
    entity_cols = [] if args.entity.lower() in ["", "none"] else [c.strip() for c in args.entity.split(",")]
    for c in entity_cols:
        if c not in df.columns: sys.exit(f"ERROR: entity column '{c}' not in table")
    if args.normalize_entity:
        for c in entity_cols: df[c] = df[c].map(norm_text)

    # filters
    if args.max_evalue is not None: df = df[df["evalue"] <= args.max_evalue]
    if args.min_pident is not None: df = df[df["pident"] >= args.min_pident]
    if args.min_scovs  is not None: df = df[df["scovs"]  >= args.min_scovs]
    if args.min_length is not None and "length" in df: df = df[df["length"] >= args.min_length]

    if df.empty:
        out_cols = original_cols + ([] if "scovs" in original_cols else ["scovs"])
        pd.DataFrame(columns=out_cols).to_csv(args.output, sep="\t", index=False); return

    # assign loci on the query
    df_loci = add_loci(df, args.gap)

    # choose grouping
    if args.mode == "query":
        keys = ["qseqid"]
    elif args.mode == "query-entity":
        keys = ["qseqid"] + entity_cols
    elif args.mode == "query-locus":
        keys = ["qseqid","locus_id"]
    else:  # query-entity-locus
        keys = ["qseqid"] + entity_cols + ["locus_id"]

    best = best_by(df_loci, keys)
    # remove helper cols
    best = best.drop(columns=["qlo","qhi","locus_id"], errors="ignore")

    # keep original order + scovs appended if it wasn't present
    if "scovs" not in original_cols:
        best = best[original_cols + ["scovs"]]
    else:
        best = best[original_cols]

    best.to_csv(args.output, sep="\t", index=False)

if __name__ == "__main__":
    main()
