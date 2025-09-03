#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse, re
import pandas as pd
from collections import defaultdict

def normalize_header(s: str) -> str:
    # unify spaces/underscores a bit, but keep original readable
    return re.sub(r"\s+", " ", str(s)).strip()

def build_group_name(col: str, exact_map: dict, regex_rules: list) -> str:
    # 1) exact map first (fast, authoritative)
    if col in exact_map:
        return exact_map[col]
    # 2) regex rules (case-insensitive patterns)
    for regex, group in regex_rules:
        if regex.search(col):
            return group
    # 3) default: keep original column name (not grouped)
    return col

def main():
    ap = argparse.ArgumentParser(
        description="Collapse virulence gene variants into logical groups."
    )
    ap.add_argument("-i", "--input", required=True, help="Input TSV (first two columns: species, genome)")
    ap.add_argument("-o", "--output", required=True, help="Output TSV (collapsed)")
    ap.add_argument("--sep", default="\t", help="Input delimiter (default: tab)")
    ap.add_argument("--report", default=None, help="Optional path to write a grouping report (TSV)")
    args = ap.parse_args()

    # --- read
    df = pd.read_csv(args.input, sep=args.sep, engine="python", encoding="utf-8-sig")
    if df.shape[1] < 3:
        raise SystemExit("Input must have ≥3 columns: species, genome, then genes…")

    # normalize headers minimally for matching
    df.columns = [normalize_header(c) for c in df.columns]

    # --- EXACT names -> group (authoritative)
    exact_map = {
        # ====== siderophores / iron systems ======
        # Salmochelin
        "Salmochelin_(CVF850)_": "Salmochelin",
        "Salmochelin_siderophore_(CVF456)_": "Salmochelin",
        "Sal_(VF0563)_": "Salmochelin",

        # Enterobactin
        "Ent_(VF0562)_": "Enterobactin",
        "Ent_siderophore_(CVF849)_": "Enterobactin",
        "enterobactin_(IA019)_": "Enterobactin",
        "Enterobactin_transport_(CVF478)_": "Enterobactin",
        "Enterobactin_(VF0228)_": "Enterobactin",
        "Enterobactin_synthesis_(CVF477)_": "Enterobactin",

        # Aerobactin
        "Aerobactin_(CVF852)_": "Aerobactin",
        "Aerobactin_siderophore_(CVF457)_": "Aerobactin",

        # Yersiniabactin
        "Yersiniabactin_siderophore_(CVF458)_": "Yersiniabactin",
        "Yersiniabactin_(CVF051)_": "Yersiniabactin",
        "Yersiniabactin_(CVF851)_": "Yersiniabactin",
        "Yersiniabactin_(VF0136)_": "Yersiniabactin",
        "yersiniabactin-related_(IA035)_": "Yersiniabactin",

        # Acinetobactin
        "Acinetobactin_(CVF768)_": "Acinetobactin",
        "Acinetobactin_(VF0467)_": "Acinetobactin",

        # Hemin/heme uptake
        "Hemin_uptake_(CVF460)_": "Heme_acquisition",
        "Heme_utilization__(CVF769)_": "Heme_acquisition",
        "Shu_(VF0256)_": "Heme_acquisition",
        "Chu_(VF0234)_": "Heme_acquisition",
        "Iron/managanease_transport_(CVF459)_": "Iron_Mn_transport",
        "Enterobactin_transport_(CVF478)_": "Enterobactin",  # already above

        # ====== efflux / stress / regulators ======
        "AcrAB_(CVF859)_": "AcrAB_efflux",
        "AcrAB_(VF0568)_": "AcrAB_efflux",
        "AdeFGH_efflux_pump_(VF0504)_": "AdeFGH_efflux",
        "AdeFGH_efflux_pump/transport_autoinducer_(CVF773)_": "AdeFGH_efflux",
        "RpoS_(VF0112)_": "RpoS",
        "Fur_(VF0113)_": "Fur",
        "PhoPQ_(CVF010)_": "PhoPQ",
        "PhoPQ_(VF0111)_": "PhoPQ",

        # ====== capsule / LPS / O-antigen ======
        "Capsule_(CVF854)_": "Capsule",
        "Capsule_(VF0560)_": "Capsule",
        "Capsule_(CVF775)_": "Capsule",
        "Capsule_(VF0465)_": "Capsule",
        "LPS_(CVF774)_": "LPS_core",
        "LPS_(VF0124)_": "LPS_core",
        "LPS_rfb_locus_(CVF857)_": "LPS_rfb",
        "O-antigen_(CVF043)_": "O_antigen",
        "O-antigen_(VF0392)_": "O_antigen",

        # ====== outer membrane / adhesins ======
        "OmpA_(AI330)_": "OmpA",
        "OmpA_(VF0236)_": "OmpA",
        "E._coli_common_pilus_(ECP)_(CVF625)_": "ECP",
        "ECP_(VF0404)_": "ECP",
        "EhaA,_AIDA-I_type_(CVF743)_": "Eha_autotransporter",
        "EhaB,_AIDA-I_type_(CVF744)_": "Eha_autotransporter",
        "AatA,_AIDA-I_type_(CVF749)_": "AIDA_I_family",
        "Cah,_AIDA-I_type_(CVF745)_": "AIDA_I_family",
        "UpaG_adhesin,_trimeric_AT_(CVF740)_": "Trimeric_autotransporter",
        "Biofilm-associated_protein_(CVF771)_": "Biofilm_associated_protein",
        "PNAG_(Polysaccharide_poly-N-acetylglucosamine)_(CVF772)_": "PNAG",
        "Agf_(VF0103)_": "Curli_fimbriae",
        "Agf/Csg_(CVF001)_": "Curli_fimbriae",
        "curli_fibers_(AI093)_": "Curli_fimbriae",
        "curli_fibers/thin_aggregative_fimbriae_(AGF)_(AI094)_": "Curli_fimbriae",

        # ====== fimbriae / pili (explicit) ======
        "Type_3_fimbriae_(CVF848)_": "Fimbriae_Type_3",
        "Type_3_fimbriae_(VF0567)_": "Fimbriae_Type_3",
        "type_3_fimbriae_(AI084)_": "Fimbriae_Type_3",
        "Type_I_fimbriae_(CVF847)_": "Fimbriae_Type_1",
        "Type_I_fimbriae_(VF0566)_": "Fimbriae_Type_1",
        "type_1_fimbriae_(AI083)_": "Fimbriae_Type_1",
        "Type_1_fimbriae_(VF0221)_": "Fimbriae_Type_1",
        "Lpf_(CVF004)_": "Fimbriae_Lpf",
        "F9_fimbriae_(AI090)_": "Fimbriae_F9",
        "Stg_fimbriae_(AI047)_": "Fimbriae_Stg",
        "Stb_(CVF020)_": "Fimbriae_Stb",
        "Kfc_fimbriae_(AI092)_": "Fimbriae_Kfc",
        "E._coli_YcbQ_laminin-binding_fimbriae_(ELF)_(AI005)_": "Fimbriae_ELF",
        "E.coli_laminin-binding_fimbriae_(ELF)_(CVF824)_": "Fimbriae_ELF",
        "colonization_factor_Citrobacter_(CFC)_type_IV_fimbriae_(AI116)_": "Fimbriae_Type_IV",
        "Hemorrhagic_E.coli_pilus_(HCP)_(CVF825)_": "HCP_pilus",

        # ====== flagella ======
        "peritrichous_flagella_(AI139)_": "Flagella",
        "peritrichous_flagella_(AI140)_": "Flagella",
        "peritrichous_flagella_(AI145)_": "Flagella",
        "Flagella_(cluster_I)_(CVF039)_": "Flagella",

        # ====== T6SS families ======
        "T6SS-I_(CVF853)_": "T6SS_I",
        "T6SS-II_(CVF861)_": "T6SS_II",
        "T6SS-III_(CVF862)_": "T6SS_III",
        "SCI-I_(SS183)_": "T6SS_I",
        "SCI-I_T6SS_(CVF734)_": "T6SS_I",
        "Hcp_secretion_island-1_encoded_type_VI_secretion_system_(H-T6SS)_(CVF535)_": "T6SS_Hcp_island",
        "ACE_T6SS_(CVF736)_": "T6SS_ACE",
        "T6SS_(VF0569)_": "T6SS_unspecified",
        "T6SS_(SS177)_": "T6SS_unspecified",

        # ====== T3SS / LEE etc. ======
        "LEE_encoded_T3SS_(SS020)_": "T3SS_LEE",
        "Mxi-Spa_TTSS_effectors_controlled_by_MxiE_(CVF465)_": "T3SS_MxiSpa",
        "ETT2_(SS017)_": "T3SS_ETT2",

        # ====== toxins / genotoxins / colicins ======
        "Colibactin_(VF0573)_": "Colibactin",
        "colibactin_(TX033)_": "Colibactin",
        "colicin_E1_(TX381)_": "Colicin",
        "colicin_Ia_(TX382)_": "Colicin",
        "Hemolysin/cytolysin_A_(CVF750)_": "ClyA",
        "Pla_(CVF044)_": "Pla",

        # ====== Csu (Acinetobacter pili) ======
        "Csu_fimbriae_(VF0461)_": "Csu_pili",
        "Csu_pili_(CVF770)_": "Csu_pili",

        # ====== misc outer membrane / OM proteins ======
        "Outer_membrane_protein_(CVF776)_": "Outer_membrane_protein",

        # ====== invasins / adhesins etc. ======
        "MisL_(CVF008)_": "MisL",
        "EaeH_(CVF679)_": "EaeH",
        "Ibes)_(CVF429)_": "Ibes",  # Invasion_of_brain_endothelial_cells_(Ibes)_(CVF429)_
        "Tsh_(VF0233)_": "Tsh",
        "Pic_(VF0232)_": "Pic",
        "AslA_(VF0238)_": "AslA",
        "VirK_(CVF483)_": "VirK",
        "Kfc_fimbriae_(AI092)_": "Fimbriae_Kfc",

        # ====== regulation / two-component etc. ======
        "Two-component_system_(CVF778)_": "Two_component_system",
        "Quorum_sensing_(CVF777)_": "Quorum_sensing",
        "RcsAB_(CVF856)_": "RcsAB",
        "RcsAB_(VF0571)_": "RcsAB",

        # ====== phospholipases ======
        "Phospholipase_C_(CVF766)_": "Phospholipase_C",
        "Phospholipase_C_(VF0470)_": "Phospholipase_C",
        "Phospholipase_D_(CVF767)_": "Phospholipase_D",

        # ====== transport / secretion islands (gsp/pul etc.) ======
        "gsp_(SS206)_": "Type_II_secretion",
        "pul_(SS215)_": "Type_II_secretion",

        # ====== misc ======
        "Allantion_utilization_(VF0572)_": "Allantoin_utilization",
        "PbpG_(CVF779)_": "PbpG",
        "Mg2+_transport_(CVF005)_": "Mg_transport",
        "Pla_(CVF044)_": "Pla",  # duplicate kept safe
        "EhaB,_AIDA-I_type_(CVF744)_": "Eha_autotransporter",
        "AES_T6SS_(CVF736)_": "T6SS_unspecified",
    }

    # --- REGEX rules (catch variants / typos) ---
    ci = re.IGNORECASE
    regex_rules = [
        # siderophores
        (re.compile(r"\bSalmochelin\b|^Sal_", ci),          "Salmochelin"),
        (re.compile(r"Enterobactin", ci),                   "Enterobactin"),
        (re.compile(r"Aerobactin", ci),                     "Aerobactin"),
        (re.compile(r"Yersiniabactin", ci),                 "Yersiniabactin"),
        (re.compile(r"Acinetobactin", ci),                  "Acinetobactin"),
        (re.compile(r"\bHemin\b|\bHeme\b|Shu|Chu", ci),     "Heme_acquisition"),
        (re.compile(r"Iron.*mangan", ci),                   "Iron_Mn_transport"),

        # efflux / stress
        (re.compile(r"\bAcrAB\b", ci),                      "AcrAB_efflux"),
        (re.compile(r"\bAdeFGH\b", ci),                     "AdeFGH_efflux"),
        (re.compile(r"\bRpoS\b", ci),                       "RpoS"),
        (re.compile(r"\bFur\b", ci),                        "Fur"),
        (re.compile(r"PhoP?Q", ci),                         "PhoPQ"),

        # envelope
        (re.compile(r"\bCapsule\b", ci),                    "Capsule"),
        (re.compile(r"\bLPS\b", ci),                        "LPS_core"),
        (re.compile(r"O-?antigen", ci),                     "O_antigen"),
        (re.compile(r"\bOmpA\b", ci),                       "OmpA"),
        (re.compile(r"rfb", ci),                            "LPS_rfb"),

        # adhesins / pili / fimbriae
        (re.compile(r"\bECP\b|common\s+pilus", ci),         "ECP"),
        (re.compile(r"\bEha[A-Z]?\b|AIDA-I", ci),           "Eha_autotransporter"),
        (re.compile(r"Trimeric.*autotransporter|UpaG", ci), "Trimeric_autotransporter"),
        (re.compile(r"\bcurli\b|Agf|Csg", ci),              "Curli_fimbriae"),
        (re.compile(r"\bType[_ ]?I\b.*fimbr", ci),          "Fimbriae_Type_1"),
        (re.compile(r"\bType[_ ]?1\b.*fimbr", ci),          "Fimbriae_Type_1"),
        (re.compile(r"\bType[_ ]?III?\b.*fimbr|Type[_ ]?3", ci), "Fimbriae_Type_3"),
        (re.compile(r"\bLpf\b", ci),                        "Fimbriae_Lpf"),
        (re.compile(r"\bF9\b.*fimbr", ci),                  "Fimbriae_F9"),
        (re.compile(r"\bStg\b.*fimbr", ci),                 "Fimbriae_Stg"),
        (re.compile(r"\bStb\b", ci),                        "Fimbriae_Stb"),
        (re.compile(r"\bKfc\b.*fimbr", ci),                 "Fimbriae_Kfc"),
        (re.compile(r"\bELF\b|laminin-binding.*fimbr", ci), "Fimbriae_ELF"),
        (re.compile(r"CFC.*type[_ ]?IV", ci),               "Fimbriae_Type_IV"),
        (re.compile(r"\bHCP\b|hemorrhagic.*pilus", ci),     "HCP_pilus"),
        (re.compile(r"\bCsu\b.*(fimbr|pili)", ci),          "Csu_pili"),

        # flagella
        (re.compile(r"\bflagella|\bflagellum|\bperitrichous", ci), "Flagella"),

        # T6SS
        (re.compile(r"\bT6SS[-_ ]?I\b", ci),                "T6SS_I"),
        (re.compile(r"\bT6SS[-_ ]?II\b", ci),               "T6SS_II"),
        (re.compile(r"\bT6SS[-_ ]?III\b", ci),              "T6SS_III"),
        (re.compile(r"SCI[-_ ]?I.*T6SS|H-?T6SS|Hcp.*island", ci), "T6SS_SCI_I"),
        (re.compile(r"ACE.*T6SS", ci),                      "T6SS_ACE"),
        (re.compile(r"\bT6SS\b", ci),                       "T6SS_unspecified"),

        # T3SS
        (re.compile(r"\bLEE\b.*T3SS|ETT2|Mxi-?Spa|TTSS", ci), "T3SS"),

        # toxins / colicins / colibactin
        (re.compile(r"\bColibactin\b|TX033", ci),           "Colibactin"),
        (re.compile(r"\bColicin\b|TX38", ci),               "Colicin"),
        (re.compile(r"ClyA|hemolysin|cytolysin", ci),       "ClyA"),

        # misc secretion
        (re.compile(r"\bgsp\b|\bpul\b", ci),                "Type_II_secretion"),
    ]

    # --- assign group for each gene column
    meta = df.iloc[:, :2].copy()
    genes_df = df.iloc[:, 2:].copy()

    # coerce to 0/1
    for c in genes_df.columns:
        genes_df[c] = pd.to_numeric(genes_df[c], errors="coerce").fillna(0).astype(int)

    col_to_group = {}
    for col in genes_df.columns:
        col_to_group[col] = build_group_name(col, exact_map, regex_rules)

    # aggregate by group: presence if ANY variant is present
    buckets = defaultdict(list)
    for col, grp in col_to_group.items():
        buckets[grp].append(col)

    collapsed = pd.DataFrame(index=df.index)
    for grp, cols in buckets.items():
        collapsed[grp] = genes_df[cols].max(axis=1)

    out = pd.concat([meta, collapsed], axis=1)

    # --- write outputs
    out.to_csv(args.output, sep="\t", index=False)
    print(f"[✓] Collapsed matrix -> {args.output}")

    # optional report
    if args.report:
        rows = []
        for grp, cols in sorted(buckets.items()):
            for c in cols:
                rows.append({"original_column": c, "group": grp})
        rep = pd.DataFrame(rows).sort_values(["group", "original_column"])
        rep.to_csv(args.report, sep="\t", index=False)
        print(f"[i] Grouping report -> {args.report}")

if __name__ == "__main__":
    main()
