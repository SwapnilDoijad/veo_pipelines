#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Download NCBI viral protein FASTA files based on assembly summaries.

Key fixes:
- Correctly reads NCBI's commented header (lines starting with '#') and uses it as column names.
- Robust TSV parsing (no CSV quoting, tolerates odd bytes).
- Heuristic viral detection by organism name (virus/phage/viroid/satellite) and any '/viral/' hint in path.
- Converts ftp:// → https:// for downloads.
- Parallel downloads with retries and clear logging.
"""

import os
import logging
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urljoin

import polars as pl
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# ------------------------- Logging ------------------------- #
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# ------------------------- HTTP utils ------------------------- #
def make_session() -> requests.Session:
    """Create a requests Session with sensible retries."""
    s = requests.Session()
    retries = Retry(
        total=5,
        backoff_factor=0.5,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=frozenset(["GET"]),
        raise_on_status=False,
        respect_retry_after_header=True,
    )
    s.mount("https://", HTTPAdapter(max_retries=retries))
    return s

def normalize_ncbi_url(ftp_path: str) -> str:
    """NCBI mirrors FTP paths over HTTPS at the same location."""
    if not ftp_path:
        return ftp_path
    ftp_path = ftp_path.strip()
    if ftp_path.startswith("ftp://"):
        return "https://" + ftp_path[len("ftp://"):]
    if ftp_path.startswith("http://"):
        return "https://" + ftp_path[len("http://"):]
    return ftp_path

# ------------------------- IO utils ------------------------- #
def sniff_ncbi_header(path: str) -> list[str]:
    """
    Find the commented header line that contains the column names.
    It typically looks like:
    # assembly_accession\tbioproject\t...\torganism_name\t...\tftp_path
    """
    with open(path, "rt", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            # Look for the header line among comment lines
            if line.startswith("#") and "assembly_accession" in line and "\t" in line:
                header = line.lstrip("#").strip()
                cols = header.split("\t")
                return [c.strip() for c in cols]
    raise RuntimeError(f"Could not find commented header with column names in: {path}")

def read_assembly_summary(path: str) -> pl.DataFrame:
    """
    Robust TSV read:
      - sniff commented header names (since NCBI prefixes the header with '#')
      - read with has_header=False but provide new_columns=<sniffed names>
      - skip all other comment lines via comment_prefix='#'
      - disable quoting (quotes are literal in TSVs)
    """
    cols = sniff_ncbi_header(path)
    return pl.read_csv(
        path,
        separator="\t",
        has_header=False,          # we provide column names explicitly
        new_columns=cols,
        comment_prefix="#",        # drop all other comment lines
        quote_char=None,
        ignore_errors=False,
        infer_schema_length=10000,
        encoding="utf8-lossy",
        null_values=["", "na", "NA", "NaN"],
        # If your Polars version supports it and lines are ragged, you can also add:
        # truncate_ragged_lines=True,
    )

# ------------------------- Viral filtering ------------------------- #
def add_is_viral_flag(df: pl.DataFrame) -> pl.DataFrame:
    """Add a boolean 'is_viral' column using path/name heuristics (case-insensitive, version-proof)."""
    # Ensure columns exist with string dtype
    need_cols = {"ftp_path": pl.Utf8, "organism_name": pl.Utf8}
    for col, dtype in need_cols.items():
        if col not in df.columns:
            df = df.with_columns(pl.lit(None, dtype=dtype).alias(col))
        else:
            df = df.with_columns(pl.col(col).cast(dtype, strict=False))

    ftp_lower = pl.col("ftp_path").fill_null("").str.to_lowercase()
    name_lower = pl.col("organism_name").fill_null("").str.to_lowercase()

    # Note: modern assembly FTP paths are under /genomes/all/... so '/refseq/viral/' rarely appears.
    # We still keep a generic '/viral/' hint, but the main signal is organism_name.
    h_path_kw = ftp_lower.str.contains("/viral/")
    h_name_kw = name_lower.str.contains(r"\b(virus|phage|viroid|satellite)s?\b")

    return df.with_columns((h_path_kw | h_name_kw).alias("is_viral"))

# ------------------------- Downloading ------------------------- #
def download_protein_file(row: dict, output_dir: str, session: requests.Session, timeout: int = 90) -> None:
    """
    Download *_protein.faa.gz from the assembly directory for a single row.
    Skips if file missing (404).
    """
    ftp = row.get("ftp_path") or row.get("ftp_url") or row.get("ftp")
    taxid = str(row.get("taxid") or "").strip()
    acc = row.get("assembly_accession") or "unknown"

    if not ftp or not taxid:
        logging.warning(f"Skipping {acc}: missing ftp_path or taxid")
        return

    base_url = normalize_ncbi_url(ftp.rstrip("/"))
    base_name = os.path.basename(base_url)
    file_name = f"{base_name}_protein.faa.gz"
    download_url = urljoin(base_url + "/", file_name)

    dest_folder = os.path.join(output_dir, taxid)
    os.makedirs(dest_folder, exist_ok=True)
    local_path = os.path.join(dest_folder, file_name)

    try:
        with session.get(download_url, stream=True, timeout=timeout) as r:
            if r.status_code == 404:
                logging.warning(f"No protein file for {acc} (404): {download_url}")
                return
            r.raise_for_status()
            with open(local_path, "wb") as f:
                for chunk in r.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        f.write(chunk)
        logging.info(f"Downloaded {acc} → {local_path}")
    except requests.RequestException as e:
        logging.error(f"Failed {acc}: {e}")

# ------------------------- Main ------------------------- #
def main():
    parser = argparse.ArgumentParser(
        description="Download viral protein FASTA files from NCBI assembly summaries."
    )
    parser.add_argument("--refseq", required=True, help="Path to the RefSeq assembly summary (TSV).")
    parser.add_argument("--genbank", required=True, help="Path to the GenBank assembly summary (TSV).")
    parser.add_argument("--output", required=True, help="Directory to write downloads into.")
    parser.add_argument("--threads", type=int, default=5, help="Parallel download threads (default: 5).")
    args = parser.parse_args()

    # Read inputs (now with header sniffing)
    try:
        refseq_df = read_assembly_summary(args.refseq)
        genbank_df = read_assembly_summary(args.genbank)
    except FileNotFoundError as e:
        logging.error(f"Input file not found: {e}")
        raise SystemExit(1)
    except Exception as e:
        logging.error(f"Failed to read TSVs: {e}")
        raise SystemExit(1)

    # Concatenate flexibly (columns might differ)
    df = pl.concat([refseq_df, genbank_df], how="diagonal_relaxed")

    # Standardize key columns
    for col, dtype in {
        "assembly_accession": pl.Utf8,
        "taxid": pl.Utf8,
        "ftp_path": pl.Utf8,
        "organism_name": pl.Utf8,
    }.items():
        if col not in df.columns:
            df = df.with_columns(pl.lit(None, dtype=dtype).alias(col))
        else:
            df = df.with_columns(pl.col(col).cast(dtype, strict=False))

    # Viral flagging
    df = add_is_viral_flag(df)

    # Helpful counts
    total = df.height
    via_name = df.filter(pl.col("organism_name").fill_null("").str.to_lowercase().str.contains(r"\b(virus|phage|viroid|satellite)s?\b")).height
    via_path = df.filter(pl.col("ftp_path").fill_null("").str.to_lowercase().str.contains("/viral/")).height
    viral = df.filter(pl.col("is_viral")).height

    logging.info(f"Total assemblies: {total}")
    logging.info(f"Viral flagged (union): {viral}")
    logging.info(f"  ├─ via organism_name keyword: {via_name}")
    logging.info(f"  └─ via '/viral/' in path: {via_path}")

    df_viral = df.filter(pl.col("is_viral"))

    rows = df_viral.select(["assembly_accession", "taxid", "ftp_path"]).to_dicts()
    if not rows:
        logging.warning(
            "No viral rows found with heuristics. For strict taxonomy, "
            "filter by taxid being a descendant of 10239 (Viruses), 12884 (Viroids), or 543314 (Viral satellites)."
        )
        return

    session = make_session()

    # Parallel downloads
    with ThreadPoolExecutor(max_workers=args.threads) as ex:
        futures = [ex.submit(download_protein_file, row, args.output, session) for row in rows]
        for _ in as_completed(futures):
            pass

if __name__ == "__main__":
    main()
