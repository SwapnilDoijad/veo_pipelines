import taxopy
import argparse

# Set up argument parser
parser = argparse.ArgumentParser(description="Convert NCBI taxonomy to ICTV taxonomy.")
parser.add_argument("--ictv_names", required=True, help="Path to the ICTV names file.")
parser.add_argument("--ncbi_nodes", required=True, help="Path to the NCBI nodes.dmp file.")
parser.add_argument("--ncbi_names", required=True, help="Path to the NCBI names.dmp file.")
parser.add_argument("--ncbi_merged", required=True, help="Path to the NCBI merged.dmp file.")
parser.add_argument("--ictv_nodes", required=True, help="Path to the ICTV nodes.dmp file.")
parser.add_argument("--ictv_names_dmp", required=True, help="Path to the ICTV names.dmp file.")
parser.add_argument("--accession_file", required=True, help="Path to the virus accession2taxid file.")
parser.add_argument("--output_file", required=True, help="Path to the output file.")

args = parser.parse_args()

# Read the official ICTV names
with open(args.ictv_names) as fin:
    ictv_name_set = {i.strip() for i in fin.readlines()}

# Create the Taxopy NCBI and ICTV databases
ncbi_taxdb = taxopy.TaxDb(
    nodes_dmp=args.ncbi_nodes,
    names_dmp=args.ncbi_names,
    merged_dmp=args.ncbi_merged,
    keep_files=True,
)
ictv_taxdb = taxopy.TaxDb(
    nodes_dmp=args.ictv_nodes,
    names_dmp=args.ictv_names_dmp,
    keep_files=True,
)

# Process the accession file
with open(args.accession_file) as fin:
    with open(args.output_file, "w") as fout:
        for line in fin:
            acc, taxid = line.split("\t")
            ncbi_taxon = taxopy.Taxon(int(taxid), ncbi_taxdb)
            for j in ncbi_taxon.name_lineage:
                if j in ictv_name_set:
                    ictv_taxid = taxopy.taxid_from_name(j, ictv_taxdb)
                    ictv_taxon = taxopy.Taxon(ictv_taxid[0], ictv_taxdb)
                    fout.write(f"{acc}\t{ictv_taxon.taxid}\n")
                    # break