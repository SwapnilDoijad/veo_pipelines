#################################  HOW TO  #######################################################
############  python Merging_MGnify_OTUs_2table.py -o File_with_Location_of_OTU_files -d OUTPUTDIRECTORY ##########
###############################  EXAMPLE ########################################################
#################  python Merging_MGnify_OTUs_2table.py -o  List_of_OTU_files.txt -d Outputdirectory ###############
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
print ('Starting NOW')
## Parse the flags
parser = argparse.ArgumentParser()
# Argument for the otu files
parser.add_argument("-o","--otus", help="File path", nargs='+',type=str)
parser.add_argument("-d","--dir", help="Output directory", nargs='+',type=str)
parser.add_argument('-t','--type',help='What do you wanna merge? (Prefix on the saved file)',nargs='?',type=str,default='')
parser.add_argument('-e','--existing',help='Do you have a file to append to?',nargs='?',type=str,default='') # FILE TO append to
# Parse the flags
args=parser.parse_args()
## Store the files in variable
file=args.otus
biome=args.type
existing=args.existing

outdir=args.dir[:-1] if args.dir[-1]=='/' else args.dir
with open (file[0],'r') as f:
        files=[i.strip() for i in f.readlines()]
# Initialize a dictionary to store the otus
files_used,wrong_ones=[],[]
## Keys= taxonomic assignments of OTUs
if not args.existing:

    otus={}
    # Just a bar to have a feeling where we are!
    with alive_progress.alive_bar(len(files),title="Parsing files") as bar:
            ## Iterate through all files
            for i in files:
                    if ' ' in i:
                            i=i.split(' ')[0]
                    bar()
                    ## Sample name comes from the structured download
                    sample_name=i.split('/')[-1].split("_")[0]

                    # Check if the MGnify pipeline is the first one
                    if "1.0" in i.split('/'):
                            continue
                    # Read the otu file
                    try:
                            df=pd.read_csv(i,sep='\t',header=0,skiprows=1)

                    except Exception as e:
                            print (e)
                            try:
                                    df=pd.read_csv(i.replace('otu','OTU'),sep='\t',header=0,skiprows=1)
                            except Exception as f:
                                    print (f)
                                    continue
                    if not len(df):
                            continue
                    if "taxonomy" not in df.columns:
                            continue

                    try:
                            # Iterate through the found taxa
                            for tax in df["taxonomy"]:
                                    # Initialize a dictionary for every new taxonomy found
                                    # Keys= sample names, values= abundance
                                    if tax not in otus.keys():
                                            otus[tax]={}
                                    # For every taxon found, a dictionary as above is created
                                    otus[tax][sample_name]=df[df["taxonomy"]==tax][sample_name].sum()
                            files_used.append(i)
                    except Exception:
    #                       print (f'Could not convert {sample_name}')
                            wrong_ones.append(sample_name)
    # Convert the dictionary as a pandas Dataframe
    # Transpose the dataframe, to have the samples as columns
    final=pd.DataFrame(otus).T

else:
        otus=pd.read_csv(args.existing,sep='\t',header=0,index_col=0)
        with alive_progress.alive_bar(len(files),title="Parsing files") as bar:
            ## Iterate through all files
            for i in files:
                    bar()
                    if ' ' in i:
                            i=i.split(' ')[0]
                    
                    ## Sample name comes from the structured download
                    sample_name=i.split('/')[-1].split("_")[0]

                    # Check if the MGnify pipeline is the first one
                    if "1.0" in i.split('/'):
                            continue
                    # Read the otu file
                    if sample_name in list(otus.columns):
                            continue
                    try:
                            df=pd.read_csv(i,sep='\t',header=0,skiprows=1)

                    except Exception as e:
                            try:
                                    df=pd.read_csv(i.replace('otu','OTU'),sep='\t',header=0,skiprows=1)
                            except Exception as f:
                                    wrong_ones.append(sample_name)
                                    continue
                    if not len(df):
                            wrong_ones.append(sample_name)
                            continue
                    if "taxonomy" not in df.columns:
                            wrong_ones.append(sample_name)
                            continue
                       # Iterate through the found taxa
                    for tax in df["taxonomy"]:
                                    # For every taxon found, a dictionary as above is created
                                    otus.loc[tax,sample_name]=df[df["taxonomy"]==tax][sample_name].sum()
                    #df.columns=sample_name
                    #otus[sample_name]=df
                   # otus=otus.join(df[sample_name],how='outer')#. pd.merge(otus,df[sample_name],left_index=True,right_index=True,how='outer')
                        #   3 print (otus.columns)
                #otus.columns=[i if i!=0 else sample_name for i in otus.columns]
                 #   print (otus.shape)
                    #otus=otus[[k for k in otus.columns if 'OTU' not in k]]
                    inters=list(set(otus.index).intersection(set(df.index)))
                    news=list(set(df.index)-set(otus.index))
                    #otus.loc[inters,sample_name]=df.loc[inters,sample_name]
                    otus.loc[news,sample_name]=df.loc[news,sample_name]
                    print (otus.shape)
                    otus=otus.fillna(0)
                    otus.to_csv(f'{outdir[0]}/{biome}_OTU_Table.tsv',sep='\t',header=True,index=True)                    
        final=otus


## Add 0, in the taxa that were not found in a sample
final=final.fillna(0)
outdir=outdir[0]
## Write the final OTU Table to a tsv file!
final.to_csv(f'{outdir}/{biome}_OTU_Table.tsv',sep='\t',header=True,index=True)
with open(f'{outdir}/Files_used_for_OTU_Table_{biome}.txt','w') as g:
        for j in files_used:
                g.write(j+'\n')
with open(f'{outdir}/Unbearable_ones{biome}.txt','w') as h:
        for k in wrong_ones:
                h.write(k+'\n')
print ("All files were parsed, thank you for your patience")
