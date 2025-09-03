#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import math
import pandas as pd
import numpy as np
from scipy.stats import chi2_contingency, fisher_exact
from statsmodels.stats.multitest import multipletests
import matplotlib.pyplot as plt
plt.switch_backend("Agg")  # safe for servers

# ------------------------ helpers ------------------------

def read_input(path, sep="\t", drop_columns=None):
    import csv
    import pandas as pd

    if drop_columns is None:
        drop_columns = []

    def try_read(_sep, note):
        return pd.read_csv(
            path,
            sep=_sep,
            engine="python",         # robust for regex/variable separators
            encoding="utf-8-sig",    # handles BOM if present
            comment=None
        ), note

    # 1) First attempt: user-provided sep
    tried = []
    try:
        df, note = try_read(sep, f"provided sep={repr(sep)}")
        tried.append(note)
    except Exception as e:
        df = None
        tried.append(f"failed with sep={repr(sep)}: {e}")

    # 2) If only 1 column, try common alternates
    if df is None or df.shape[1] < 2:
        for alt in ["\t", ",", r"\s+",";","|"]:
            try:
                df2, note = try_read(alt, f"fallback sep={repr(alt)}")
                if df2.shape[1] >= 2:
                    df = df2
                    tried.append(note)
                    break
                else:
                    tried.append(f"fallback sep={repr(alt)} -> {df2.shape[1]} cols")
            except Exception as e:
                tried.append(f"fallback sep={repr(alt)} failed: {e}")

    # 3) As a last resort, sniff with csv.Sniffer
    if df is None or df.shape[1] < 2:
        with open(path, "r", encoding="utf-8-sig") as fh:
            sample = "".join([next(fh) for _ in range(10)])
        try:
            dialect = csv.Sniffer().sniff(sample, delimiters="\t,;| ")
            sniff_sep = dialect.delimiter if dialect.delimiter != " " else r"\s+"
            df, note = try_read(sniff_sep, f"sniffer sep={repr(sniff_sep)}")
            tried.append(note)
        except Exception as e:
            tried.append(f"sniffer failed: {e}")

    # 4) If still not ok, raise with helpful context
    if df is None or df.shape[1] < 2:
        with open(path, "r", encoding="utf-8-sig") as fh:
            first_lines = "".join([next(fh) for _ in range(3)])
        raise ValueError(
            "Could not parse at least two columns (species, genome). "
            f"Tried: {tried}\nFirst lines:\n{first_lines}"
        )

    # Normalize first two columns to species/genome if needed
    cols = list(df.columns)
    # Strip whitespace from headers
    cols = [str(c).strip() for c in cols]
    df.columns = cols

    # If headers already contain 'species' and 'genome', leave them;
    # otherwise rename first two to canonical names.
    lc = [c.lower() for c in cols]
    if "species" not in lc or "genome" not in lc:
        if len(cols) >= 2:
            cols[0] = "species"
            cols[1] = "genome"
            df.columns = cols

    if "species" not in [c.lower() for c in df.columns] or "genome" not in [c.lower() for c in df.columns]:
        raise ValueError(
            "Header must contain columns identifiable as 'species' and 'genome' "
            f"(got: {list(df.columns)[:5]} ...)."
        )

    # Ensure canonical casing
    rename_map = {}
    for c in df.columns:
        if c.lower() == "species": rename_map[c] = "species"
        if c.lower() == "genome":  rename_map[c] = "genome"
    df = df.rename(columns=rename_map)

    # Coerce gene columns to integer 0/1
    for c in df.columns[2:]:
        df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0).astype(int)

    # Optional: drop completely empty gene columns
    empty = [c for c in df.columns[2:] if df[c].sum() == 0 and df[c].nunique() == 1]
    if empty:
        # Keep them if you prefer; otherwise uncomment the next line:
        # df = df.drop(columns=empty)
        pass

    # Drop specified columns
    df = df.drop(columns=drop_columns, errors="ignore")

    return df

def global_tests(df, genes, fdr_method, min_expected=5, K_perm=0, seed=0):
    """
    One global test per gene across all species.
    If χ² assumptions fail and K_perm>0, compute permutation p-value.
    """
    rng = np.random.default_rng(seed)
    rows = []
    species = df["species"].values
    for gene in genes:
        y = df[gene].values
        tab = pd.crosstab(df["species"], df[gene])  # r x 2
        for v in (0, 1):
            if v not in tab.columns:
                tab[v] = 0
        tab = tab[[0, 1]]
        try:
            chi2, p, dof, exp = chi2_contingency(tab)

            # Assumption check (80% rule)
            exp_flat = exp.ravel()
            prop_lt5 = (exp_flat < 5).mean()
            any_lt1 = (exp_flat < 1).any()
            violated = any_lt1 or prop_lt5 > 0.20

            if violated and K_perm > 0:
                # permutation p-value
                stat_obs = chi2
                ge = 0
                for _ in range(K_perm):
                    y_perm = rng.permutation(y)
                    tab_p = pd.crosstab(species, y_perm)
                    for v in (0, 1):
                        if v not in tab_p.columns:
                            tab_p[v] = 0
                    tab_p = tab_p[[0, 1]]
                    chi2_p, _, _, _ = chi2_contingency(tab_p)
                    if chi2_p >= stat_obs:
                        ge += 1
                p_perm = (ge + 1) / (K_perm + 1)  # add-1 smoothing
                rows.append({"gene": gene, "test": "chi2_perm", "pvalue": p_perm,
                             "dof": dof, "note": f"perm({K_perm}); {int(prop_lt5*100)}% exp<5"})
            elif violated:
                rows.append({"gene": gene, "test": "chi2", "pvalue": np.nan, "dof": dof,
                             "note": f"skipped: {int(prop_lt5*100)}% exp<5 or some <1"})
            else:
                rows.append({"gene": gene, "test": "chi2", "pvalue": p, "dof": dof, "note": ""})

        except Exception as e:
            rows.append({"gene": gene, "test": "chi2", "pvalue": np.nan, "dof": np.nan, "note": f"error: {e}"})

    out = pd.DataFrame(rows)
    mask = out["pvalue"].notna()
    out["p_adj"] = np.nan
    if mask.any():
        out.loc[mask, "p_adj"] = multipletests(out.loc[mask, "pvalue"].values, method=fdr_method)[1]
    return out


def pairwise_tests(df, genes, fdr_method, min_count=5):
    """
    For each species and gene, build a 2x2:
        species present vs others  |  gene present vs absent
    Use Fisher's exact (2x2) with odds ratio as effect size.
    """
    species_list = sorted(df["species"].unique())
    rows = []
    for sp in species_list:
        mask_sp = df["species"] == sp
        n_sp = mask_sp.sum()
        n_other = len(df) - n_sp
        for gene in genes:
            a = (df.loc[mask_sp, gene] == 1).sum()            # sp & gene+
            b = (df.loc[mask_sp, gene] == 0).sum()            # sp & gene-
            c = (df.loc[~mask_sp, gene] == 1).sum()           # others & gene+
            d = (df.loc[~mask_sp, gene] == 0).sum()           # others & gene-

            # Guard against degenerate table
            table = np.array([[a, b], [c, d]])
            try:
                orr, p = fisher_exact(table, alternative="two-sided")
            except Exception:
                orr, p = np.nan, 1.0

            prev_sp = a / max(n_sp, 1)
            prev_other = c / max(n_other, 1)
            prev_diff = prev_sp - prev_other
            # log2(OR) (stabilize with Haldane-Anscombe correction if needed)
            if any(x == 0 for x in [a, b, c, d]):
                a2, b2, c2, d2 = a + 0.5, b + 0.5, c + 0.5, d + 0.5
                log2or = math.log2((a2*d2)/(b2*c2))
            else:
                log2or = math.log2((a*d)/(b*c))
            rows.append({
                "species": sp, "gene": gene,
                "a_sp_gene1": a, "b_sp_gene0": b,
                "c_other_gene1": c, "d_other_gene0": d,
                "odds_ratio": orr, "log2_or": log2or,
                "pvalue": p,
                "prev_species": prev_sp, "prev_others": prev_other,
                "prev_diff": prev_diff
            })
    out = pd.DataFrame(rows)
    out["p_adj"] = multipletests(out["pvalue"].values, method=fdr_method)[1]
    return out

def prevalence_table(df, genes):
    prev = df.groupby("species")[genes].mean() * 100.0
    return prev.sort_index()

# ------------------------ plotting ------------------------

def plot_prevalence_heatmap(prev_df, out_png, title="Gene prevalence (%) by species", dpi=180):
    """
    prev_df: species x genes (percent)
    """
    fig, ax = plt.subplots(figsize=(max(8, prev_df.shape[1] * 0.25), max(4, prev_df.shape[0] * 0.25)))
    im = ax.imshow(prev_df.values, aspect="auto")
    ax.set_xticks(np.arange(prev_df.shape[1]))
    ax.set_yticks(np.arange(prev_df.shape[0]))
    ax.set_xticklabels(prev_df.columns, rotation=90)
    ax.set_yticklabels(prev_df.index)
    ax.set_title(title)
    cbar = fig.colorbar(im, ax=ax)
    cbar.set_label("Prevalence (%)")
    fig.tight_layout()
    fig.savefig(out_png, dpi=dpi)
    # Save as SVG
    out_svg = out_png.replace(".png", ".svg")
    fig.savefig(out_svg, format="svg")
    plt.close(fig)

def plot_pairwise_bubbles(pair_df, out_png, alpha=0.05, max_size=300, dpi=180,
                          title="Species-specific gene distribution (pairwise Fisher, FDR)"):
    """
    Bubble plot: x = species, y = gene
      - size = -log10(FDR) for significant points; tiny for non-sig
      - color: blue (enriched), red (under-represented), light grey (non-sig)
      - ubiquity (all 1s) or invariance (all 0s) -> treated as non-sig/grey
    """
    df = pair_df.copy()

    # Non-significant mask
    sig = df["p_adj"] < alpha

    # -log10(FDR) for size
    df["neglog10_fdr"] = -np.log10(np.clip(df["p_adj"], 1e-300, 1.0))
    if sig.any():
        max_sig = df.loc[sig, "neglog10_fdr"].max()
    else:
        max_sig = 1.0

    # Size scaling
    sizes = np.where(sig,
                     np.clip((df["neglog10_fdr"] / max_sig) * max_size, 20, max_size),
                     8.0)

    # Colors:
    # - significant & prev_diff > 0 -> blue (enriched)
    # - significant & prev_diff <= 0 -> red (under-represented)
    # - non-significant -> light grey
    prev_diff = df.get("prev_diff", pd.Series(np.zeros(len(df))))
    colors = np.where(sig,
                      np.where(prev_diff > 0, "blue", "red"),
                      "lightgrey")

    # Axes ordering
    species_order = sorted(df["species"].unique())
    gene_order = sorted(df["gene"].unique())
    sp_index = {s: i for i, s in enumerate(species_order)}
    gene_index = {g: i for i, g in enumerate(gene_order)}
    x = df["species"].map(sp_index).values
    y = df["gene"].map(gene_index).values

    fig, ax = plt.subplots(figsize=(max(10, len(species_order)*0.5), max(9, len(gene_order)*0.3)))
    ax.scatter(x, y, s=sizes, c=colors, alpha=0.85)
    ax.set_xticks(range(len(species_order)))
    ax.set_xticklabels(species_order, rotation=90)
    ax.set_yticks(range(len(gene_order)))
    ax.set_yticklabels(gene_order)
    ax.set_title(title, fontsize=12, fontweight="bold")
    ax.set_xlabel("Species", fontsize=12, fontweight="bold")
    ax.set_ylabel("Gene-group", fontsize=12, fontweight="bold")

    # Legend
    from matplotlib.lines import Line2D
    legend_elems = [
        Line2D([0],[0], marker='o', color='w', markerfacecolor='blue', markersize=10, label='Higher prevalence'),
        Line2D([0],[0], marker='o', color='w', markerfacecolor='red',  markersize=10, label='Lower prevalence'),
        Line2D([0],[0], marker='o', color='w', markerfacecolor='lightgrey', markersize=10, label='No significant difference'),
    ]
    ax.legend(handles=legend_elems, loc="lower left", bbox_to_anchor=(-0.25, -0.45),
              frameon=False, title="Occurence of virulence genes")
    fig.tight_layout()
    fig.savefig(out_png, dpi=dpi)
    fig.savefig(out_png.replace(".png", ".svg"), format="svg")
    plt.close(fig)


# ------------------------ main ------------------------

def main():
    p = argparse.ArgumentParser(
        description="Association between species and virulence genes with visualization."
    )
    p.add_argument("-i", "--input", required=True,
                   help="Input TSV with columns: species, genome, then 0/1 gene columns")
    p.add_argument("-o", "--output", required=True,
                   help="Output prefix for files (e.g., results/run1)")
    p.add_argument("--sep", default="\t", help="Input delimiter (default: tab)")
    p.add_argument("--mode", default="both", choices=["global", "pairwise", "both"],
                   help="Run global chi-square, pairwise Fisher, or both (default).")
    p.add_argument("--alpha", type=float, default=0.05, help="FDR significance threshold (default 0.05)")
    p.add_argument("--fdr", default="fdr_bh",
                   help="Multiple-testing correction method (statsmodels, default fdr_bh)")
    p.add_argument("--min_expected", type=float, default=5.0,
                   help="Min expected count guideline for chi-square (informational).")
    p.add_argument("--no-plots", action="store_true", help="Skip plot generation")
    p.add_argument("--drop", nargs="*", default=[],
                   help="Columns to drop from the input file (default: none)")
    p.add_argument("--min_occurence_of_gene", type=int, default=0,
                   help="Minimum occurrence of a gene to keep its column (default: 0, keep all)")
    p.add_argument("--drop_species", type=str, default=None,
                   help="Comma-separated list of species to drop from the input table")
    p.add_argument("--global_permutations", type=int, default=0,
                    help="If >0, run permutation p-value for global tests when χ² assumptions fail (e.g., 5000).")
    p.add_argument("--seed", type=int, default=0, help="Random seed for permutations")
    p.add_argument("--min_n_per_species", type=int, default=0,
                    help="Drop species with < N genomes before tests")
    args = p.parse_args()

    os.makedirs(os.path.dirname(args.output), exist_ok=True) if os.path.dirname(args.output) else None

    # Read & prepare
    df = read_input(args.input, sep=args.sep, drop_columns=args.drop)

    # Filter rows based on species to drop
    if args.drop_species:
        drop_species_list = [s.strip() for s in args.drop_species.split(",")]
        initial_count = len(df)
        df = df[~df["species"].isin(drop_species_list)]
        print(f"[✓] Dropped {initial_count - len(df)} rows for species: {', '.join(drop_species_list)}")

    # Drop species with too few genomes
    if args.min_n_per_species > 0:
        counts = df["species"].value_counts()
        small = counts[counts < args.min_n_per_species].index.tolist()
        if small:
            df = df[~df["species"].isin(small)]
            print(f"[i] Dropped species with <{args.min_n_per_species} genomes: {', '.join(small)}")

    # Filter columns based on minimum occurrence of genes
    if args.min_occurence_of_gene > 0:
        gene_columns = df.columns[2:]
        gene_sums = df[gene_columns].sum()
        keep_genes = gene_sums[gene_sums >= args.min_occurence_of_gene].index
        df = df[['species', 'genome'] + list(keep_genes)]
        print(f"[✓] Filtered genes with fewer than {args.min_occurence_of_gene} occurrences")
    
    n_species = df['species'].nunique()
    if n_species < 2:
        raise SystemExit(f"Need at least 2 species for association tests (have {n_species}).")
    
    gene_cols = df.columns[2:]
    invariant = [g for g in gene_cols if df[g].nunique(dropna=False) <= 1]
    if invariant:
        df = df.drop(columns=invariant)
        print(f"[i] Dropped invariant genes (all 0 or all 1): {len(invariant)}")

    if df.shape[1] <= 2:
        raise SystemExit("No gene columns left after filtering; nothing to test.")

    genes = list(df.columns[2:])

    # Prevalence table
    prev = prevalence_table(df, genes)
    prev_csv = f"{args.output}_prevalence.csv"
    prev.to_csv(prev_csv)
    print(f"[✓] Prevalence table -> {prev_csv}")

    # Global tests
    if args.mode in ("global", "both"):
        global_df = global_tests(df, genes, fdr_method=args.fdr, min_expected=args.min_expected, K_perm=args.global_permutations, seed=args.seed)
        g_csv = f"{args.output}_global_association.csv"
        global_df.to_csv(g_csv, index=False)
        print(f"[✓] Global (across species) gene tests -> {g_csv}")
    else:
        global_df = None

    # Pairwise tests (species vs others)
    if args.mode in ("pairwise", "both"):
        pair_df = pairwise_tests(df, genes, fdr_method=args.fdr)
        p_csv = f"{args.output}_pairwise_association.csv"
        pair_df.to_csv(p_csv, index=False)
        print(f"[✓] Pairwise (species vs others) tests -> {p_csv}")
    else:
        pair_df = None

    # Plots
    if not args.no_plots:
        heat_png = f"{args.output}_prevalence_heatmap.png"
        plot_prevalence_heatmap(prev, heat_png, title="Gene prevalence (%) by species")
        print(f"[✓] Prevalence heatmap -> {heat_png}")

        if pair_df is not None and len(pair_df):
            bubble_png_pairwise = f"{args.output}_pairwise_bubble.png"
            plot_pairwise_bubbles(pair_df, bubble_png_pairwise, alpha=args.alpha)
            print(f"[✓] Pairwise enrichment bubble plot -> {bubble_png_pairwise}")

    # Quick console summary
    if pair_df is not None:
        sig = pair_df[pair_df["p_adj"] < args.alpha].copy()
        sig = sig.sort_values(["p_adj", "species", "gene"]).head(20)
        if len(sig):
            print("\nTop significant species–gene pairs (FDR < {:.3g}):".format(args.alpha))
            print(sig[["species", "gene", "p_adj", "odds_ratio", "prev_species", "prev_others", "prev_diff"]].to_string(index=False))
        else:
            print("\nNo significant pairwise associations at FDR < {:.3g}".format(args.alpha))

    if global_df is not None:
        gsig = global_df[global_df["p_adj"] < args.alpha].sort_values("p_adj").head(20)
        if len(gsig):
            print("\nTop significant global genes (FDR < {:.3g}):".format(args.alpha))
            print(gsig[["gene", "p_adj", "dof"]].to_string(index=False))
        else:
            print("\nNo significant global gene associations at FDR < {:.3g}".format(args.alpha))

if __name__ == "__main__":
    main()
