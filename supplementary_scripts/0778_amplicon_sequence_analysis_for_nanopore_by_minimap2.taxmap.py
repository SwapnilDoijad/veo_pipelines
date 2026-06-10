#!/usr/bin/env python3

import argparse

TAXMAP = "/veodata/03/databases/silva/silva_16s_138.2/taxmap_slv_ssu_ref_nr_138.2.txt"


def load_taxmap():
    """
    Load SILVA taxmap into memory.

    Key:
        accession.start.stop

    Example:
        CP028432.225068.226621

    Value:
        taxid, genus, species, organism_name, taxonomy_path
    """

    lookup = {}

    with open(TAXMAP) as fh:

        header = next(fh)

        for line in fh:

            fields = line.rstrip("\n").split("\t")

            if len(fields) < 6:
                continue

            accession = fields[0]
            start = fields[1]
            stop = fields[2]
            path = fields[3]
            organism_name = fields[4]
            taxid = fields[5]

            silva_id = f"{accession}.{start}.{stop}"

            # -------------------------
            # genus
            # -------------------------
            genus = "NA"

            if organism_name != "unidentified":

                genus = organism_name.split()[0]

            if genus == "NA":

                taxa = [x for x in path.split(";") if x]

                if taxa:
                    genus = taxa[-1]

            # -------------------------
            # species
            # -------------------------
            species = "NA"

            if organism_name != "unidentified":

                species = organism_name

                # remove common names
                if "(" in species:
                    species = species.split("(")[0].strip()

                # Bacillus sp. AK50 -> species unknown
                if " sp." in species:
                    species = "NA"

            lookup[silva_id] = (
                taxid,
                genus,
                species,
                organism_name,
                path
            )

    return lookup


def get_identity_from_dv(fields):
    """
    Extract minimap2 dv:f tag.

    identity = 1 - dv
    """

    for field in fields[12:]:

        if field.startswith("dv:f:"):

            dv = float(field.split(":")[-1])

            return 1.0 - dv

    return 0.0


def main():

    parser = argparse.ArgumentParser(
        description="Map minimap2 PAF hits to SILVA taxonomy and keep best hit per read."
    )

    parser.add_argument(
        "-i",
        required=True,
        help="Input PAF file"
    )

    parser.add_argument(
        "-o",
        required=True,
        help="Output taxonomy TSV"
    )

    parser.add_argument(
        "--min_coverage",
        type=float,
        default=0.50,
        help="Minimum query coverage (default: 0.50)"
    )

    parser.add_argument(
        "--min_identity",
        type=float,
        default=0.90,
        help="Minimum identity (default: 0.90)"
    )

    args = parser.parse_args()

    print("Loading SILVA taxonomy...")

    lookup = load_taxmap()

    print(f"Loaded {len(lookup):,} SILVA entries")

    print("Processing PAF...")

    best_hits = {}

    with open(args.i) as paf:

        for line in paf:

            if not line.strip():
                continue

            fields = line.rstrip("\n").split("\t")

            if len(fields) < 12:
                continue

            read_id = fields[0]

            qlen = int(fields[1])
            qstart = int(fields[2])
            qend = int(fields[3])

            target = fields[5]

            aligned_bases = qend - qstart

            coverage = aligned_bases / qlen

            identity = get_identity_from_dv(fields)

            if coverage < args.min_coverage:
                continue

            if identity < args.min_identity:
                continue

            score = coverage * identity

            if (
                read_id not in best_hits
                or score > best_hits[read_id]["score"]
            ):

                best_hits[read_id] = {
                    "target": target,
                    "coverage": coverage,
                    "identity": identity,
                    "score": score
                }

    print(f"Selected best hit for {len(best_hits):,} reads")

    print("Writing output...")

    with open(args.o, "w") as out:

        out.write(
            "read_id\t"
            "silva_id\t"
            "taxid\t"
            "genus\t"
            "species\t"
            "coverage\t"
            "identity\t"
            "score\t"
            "organism_name\t"
            "taxonomy\n"
        )

        for read_id, hit in best_hits.items():

            target = hit["target"]

            # Example:
            # CP028432.225068.226621_Bacteria;...
            silva_id = target.split("_")[0]

            if silva_id not in lookup:

                out.write(
                    f"{read_id}\t"
                    f"{silva_id}\t"
                    "NA\tNA\tNA\t"
                    f"{hit['coverage']:.4f}\t"
                    f"{hit['identity']:.4f}\t"
                    f"{hit['score']:.4f}\t"
                    "NA\tNA\n"
                )

                continue

            taxid, genus, species, organism_name, path = lookup[silva_id]

            out.write(
                f"{read_id}\t"
                f"{silva_id}\t"
                f"{taxid}\t"
                f"{genus}\t"
                f"{species}\t"
                f"{hit['coverage']:.4f}\t"
                f"{hit['identity']:.4f}\t"
                f"{hit['score']:.4f}\t"
                f"{organism_name}\t"
                f"{path}\n"
            )

    print("Done")


if __name__ == "__main__":
    main()