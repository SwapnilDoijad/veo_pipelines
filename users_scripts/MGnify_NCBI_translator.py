######################################## HOW TO #####################################
## python MGnify_NCBI_translator.py -t TAXONOMY_FILE -o OUTPUT_DIRECTORY -c names ##
################################# EXAMPLE ###########################################
####### python MGnify_NCBI_translator.py -t All_MGnify_OTUs.txt -o . -c names #######


import sys
import os
import argparse
try:
    import ete3
except ImportError:
    os.system('pip install ete3')
    import ete3
from ete3 import NCBITaxa
import pandas as pd





## Check that the flags are there
parser = argparse.ArgumentParser()
# Argument for the Taxonomies file
parser.add_argument("-t","--Taxfile", help="Taxonomy file ", nargs='?', type=str, default='../Time-series_data/All_MGnify_OTUs.txt')
# Argument for the output directory
parser.add_argument("-o","--outdir", help="Output directory", nargs='?', type=str, const=1, default='../Time-series_data/Graphs_of_OTUS/')
# Argument about the type of conversion
parser.add_argument("-c","--Conversion", help="You want the IDs or the full names", nargs='?', type=str, default='name')
args=parser.parse_args()

# Parse the arguments
outdir=args.outdir if args.outdir[-1]!='/' else args.outdir[:-1]
taxfile=args.Taxfile
if args.Conversion is not None:
    if args.Conversion not in ['id','name']:
        print ('-c should be either id or name')
        print ('Example:')
        print ('python MGnify_NCBI_translator.py -t All_MGnify_OTUs.txt -o ./ -c id')
        sys.exit()
    conv=args.Conversion
# Load NCBI taxonomy database
ncbi = NCBITaxa()
# Initialize a dir to store the unique NCBI IDs
Mgnify_NCBI_translator={}
# Parse the taxonomy file
with open (taxfile,'r') as f:
    t=[i.strip() for i in f.readlines() if '_' in i]
# Select only the unique taxonomic assignments
uniqt=set(t)
# Iterate through the unique taxonomic assignments
for i in uniqt:
    # Split the taxonomy and filter for non '' values and reverse it
    fulltax=[k for k in i.split('; ') if len(k)>3][::-1]
    # Try for each assignment to find the corresponding NCBI ID
    for j in fulltax:
        # When it is a species, we need to add the Genus assignment as well
        if j[0]=='s':
            tra=fulltax[fulltax.index(j)+1][3:]+' '+j[3:]
        else:
            tra=j[3:]
        translation=ncbi.get_name_translator([tra])
        if translation:
            if conv=='id':
                d={i:translation[tra][0]}
            else:                
                d={i:'; '.join([(ncbi.get_taxid_translator([l])[l]) for l in ncbi.get_lineage((translation[tra])[0])])}
            Mgnify_NCBI_translator.update(d)
# Save it to dataframe to write a table with them
df=pd.DataFrame.from_dict(Mgnify_NCBI_translator,orient='index')
# Write the table
df.to_csv('{}/MgnifyTaxonomicAssignment_to_NCBI_ID.tsv'.format(outdir),sep='\t')