################################  HOW TO  #######################################################
############  python Merging_MGnify_OTUs_2table.py -o File_with_Location_of_OTU_files  ##########
###############################  EXAMPLE ########################################################
#################  python Merging_MGnify_OTUs_2table.py -o  List_of_OTU_files.txt ###############
#################################################################################################


''' Excluded:
	MGnify pipeline 1.0
'''

## Import the built-ins
#########% BUILT INS (for when we want to check the complete requirements)
#########% print(sys.builtin_module_names)
import sys,os
import pandas as pd
import argparse
try:
	import alive_progress
except ImportError:
	os.system("pip install alive_progress")
	import alive_progress

## Parse the flags
parser = argparse.ArgumentParser()
# Argument for the otu files
parser.add_argument("-o","--otus", help="Output directory", nargs='+',type=str)
# Parse the flags
args=parser.parse_args()
## Store the files in variable
file=args.otus

with open (file[0],'r') as f:
	files=[i.strip() for i in f.readlines()]

# Initialize a dictionary to store the otus
## Keys= taxonomic assignments of OTUs
otus={}
files_used=[]
# Just a bar to have a feeling where we are!
with alive_progress.alive_bar(len(files),title="Parsing files") as bar:
	## Iterate through all files
	for i in files:
		bar()
		## Sample name comes from the structured download
		sample_name=i.split('/')[-1].split("_")[0]
		# Check if the MGnify pipeline is the first one
		if "1.0" in i.split('/'):
			continue
		# Read the otu file
		df=pd.read_csv(i,sep='\t',header=0,skiprows=1)
		if "taxonomy" not in df.columns:
			continue
		# Iterate through the found taxa
		for tax in df["taxonomy"]:
			# Initialize a dictionary for every new taxonomy found
			# Keys= sample names, values= abundance
			if tax not in otus.keys():
				otus[tax]={}
			# For every taxon found, a dictionary as above is created
			otus[tax][sample_name]=df[df["taxonomy"]==tax][sample_name].sum()
		files_used.append(i)
# Convert the dictionary as a pandas Dataframe
# Transpose the dataframe, to have the samples as columns
df=pd.DataFrame(otus).T

## Add 0, in the taxa that were not found in a sample
df=df.fillna(0)
## Write the final OTU Table to a tsv file!
df.to_csv('merged.tsv',sep='\t')
with open('Files_used_for_OTU_Table.txt','w') as g:
	for j in files_used:
		g.write(j+'\n')

print ("All files were parsed, thank you for your patience")
