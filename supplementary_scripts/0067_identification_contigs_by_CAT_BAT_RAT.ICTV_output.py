# -*- coding: utf-8 -*-
"""
Created on Fri Dec 20 10:30:05 2024

@author: Ernestina Hauptfeld
"""

ICTV_ranks=['clade', 'subrealm', 'kingdom', 'subkingdom', 'phylum', 'subphylum', 
            'class', 'subclass', 'order', 'suborder', 'family', 'subfamily', 
            'genus', 'subgenus', 'species']


def make_ncbi2ictv_dict(input_file):
    ncbi2ictv={}
    
    tmp=open(input_file).read().strip().split('\n')[3:]
        
    for acc in tmp:
        acc=acc.split('\t')
        
        taxid=acc[2]
        accession=acc[0]
        ictv_species=acc[4].split(';')
        ncbi_species=acc[6].split(';')
        ncbi_ranks=acc[7].split(';')
        ncbi_taxids=acc[5].split(';')
        
        if taxid not in ncbi2ictv:
            ncbi2ictv[taxid]={'accessions': [],
                              'ictv': [],
                              'ncbi': [],
                              'ncbi_ranks': [],
                              'ncbi_taxids': []}
        
        ncbi2ictv[taxid]['accessions'].append(accession)
        ncbi2ictv[taxid]['ictv'].append(ictv_species)
        ncbi2ictv[taxid]['ncbi'].append(ncbi_species)
        ncbi2ictv[taxid]['ncbi_ranks'].append(ncbi_ranks)
        ncbi2ictv[taxid]['ncbi_taxids'].append(ncbi_taxids)
        
        for rank in ncbi_ranks:
            if rank in ICTV_ranks:
                short_lineage=ncbi_taxids[:ncbi_ranks.index(rank)+1]
                new_taxid=short_lineage[-1]
                short_names=ncbi_species[:ncbi_ranks.index(rank)+1]
                short_ranks=ncbi_ranks[:ncbi_ranks.index(rank)+1]
                short_ictv=ictv_species[:ICTV_ranks.index(rank)+1]
                if new_taxid not in ncbi2ictv:
                    ncbi2ictv[new_taxid]={'accessions': [],
                                      'ictv': [],
                                      'ncbi': [],
                                      'ncbi_ranks': [],
                                      'ncbi_taxids': []}
                ncbi2ictv[new_taxid]['ictv'].append(short_ictv)
                ncbi2ictv[new_taxid]['ncbi'].append(short_names)
                ncbi2ictv[new_taxid]['ncbi_ranks'].append(short_ranks)
                ncbi2ictv[new_taxid]['ncbi_taxids'].append(short_lineage)
        
    return ncbi2ictv


# def make_c2c_dict(c2c_file):
#     c2c={}
    
#     tmp=open(c2c_file).read().strip().split('\n')[1:]
    
#     for contig in tmp:
#         contig=contig.replace('*','').split('\t')
#         contig_id=contig[0]
#         c2c[contig_id]={'lineage': [],
#                      'ranks': [],
#                      'scores': [],
#                      'names': []}
        
#         if contig[1]!='no taxid assigned':
#             lineage=contig[3].split(';')
#             scores=contig[4].split(';')
            
#             names_ranks=contig[5:]
#             names=[]
#             ranks=[]
#             for r in names_ranks:
#                 try:
#                     name = r.split(' (')[0]
#                     rank = r.split(' (')[1].split('):')[0]
#                     names.append(name)
#                     ranks.append(rank)
#                 except IndexError:
#                     print(f"Warning: Unexpected format in names_ranks: {r}")
#                     continue
            
#             c2c[contig_id]['lineage']=lineage
#             c2c[contig_id]['scores']=scores
#             c2c[contig_id]['ranks']=ranks
#             c2c[contig_id]['names']=names
            
#     return c2c
        
def make_c2c_dict(c2c_file):
    c2c = {}
    with open(c2c_file) as fh:
        lines = [ln.rstrip('\n') for ln in fh if ln.strip()]

    header = lines[0].split('\t')
    # columns: 0 contig, 1 classification, 2 reason, 3 lineage, 4 lineage scores, 5.. ranks
    rank_cols = header[5:]  # e.g., superkingdom, phylum, class, ...

    for line in lines[1:]:
        cols = line.replace('*', '').split('\t')
        contig_id = cols[0]
        c2c[contig_id] = {
            'lineage': [],
            'ranks': rank_cols[:],   # take from header
            'scores': [],            # lineage scores (the semicolon list)
            'names': []              # taxon names aligned to rank_cols
        }

        if len(cols) > 1 and cols[1] != 'no taxid assigned':
            # lineage + lineage scores
            if len(cols) > 3 and cols[3]:
                c2c[contig_id]['lineage'] = cols[3].split(';')
            if len(cols) > 4 and cols[4]:
                c2c[contig_id]['scores'] = cols[4].split(';')

            # per-rank cells: "Name: score" or "NA"/"no support"
            names = []
            per_rank_cells = cols[5:]
            for cell in per_rank_cells:
                cell = cell.strip()
                if not cell or cell.lower() == 'na' or cell.lower() == 'no support':
                    names.append(None)
                    continue
                # usual form is "TaxonName: number"
                if ':' in cell:
                    name, _score = cell.split(':', 1)
                    names.append(name.strip())
                else:
                    # fallback: keep whatever is there
                    names.append(cell)
            # pad or trim to match rank columns, just in case
            if len(names) < len(rank_cols):
                names += [None] * (len(rank_cols) - len(names))
            c2c[contig_id]['names'] = names[:len(rank_cols)]

    return c2c

def find_LCA(list_of_lineages):
    lca=[]
    overlap = set.intersection(*map(set, list_of_lineages))

    for taxid in list_of_lineages[0]:
        if taxid in overlap:
            lca.append(taxid)
        else:
            break
    return lca


def make_challenge_output_direct(c2c_dict, output_file):
    output_dict={}
    for contig in c2c_dict:
        output_dict[contig]={'names': len(ICTV_ranks)*['NA'],
                             'scores': len(ICTV_ranks)*['NA']}
        for rank in ICTV_ranks:
            if rank in c2c_dict[contig]['ranks']:
                c2c_index=c2c_dict[contig]['ranks'].index(rank)
                output_index=ICTV_ranks.index(rank)
                
                # safe-access names and scores (some contigs may have empty lists)
                names_list = c2c_dict[contig].get('names', [])
                scores_list = c2c_dict[contig].get('scores', [])
                
                name_val = 'NA'
                score_val = 'NA'
                if c2c_index < len(names_list) and names_list[c2c_index] is not None:
                    name_val = names_list[c2c_index]
                if c2c_index < len(scores_list) and scores_list[c2c_index] is not None:
                    score_val = scores_list[c2c_index]
                
                output_dict[contig]['names'][output_index] = name_val
                output_dict[contig]['scores'][output_index] = score_val
                
    
    with open(output_file, 'w') as outf:
        outf.write('SequenceID,realm,realm_score,subrealm,subrealm_score')
        for rank in ICTV_ranks[2:]:
            outf.write(f',{rank},{rank}_score')
        outf.write('\n')
        
        for contig in output_dict:
            outf.write(contig)
            for i in range(0, len(ICTV_ranks)):
                outf.write(f",{output_dict[contig]['names'][i]},{output_dict[contig]['scores'][i]}")
            outf.write('\n')
        
    return


def make_challenge_output_mapped(c2c_dict, ncbi2ictv,output_file):
    n=0
    output_dict={}
    for contig in c2c_dict:
        n+=1
        if n%1000==0:
            print(f'done with {n} contigs!')
        output_dict[contig]={'names': len(ICTV_ranks)*['NA'],
                             'scores': len(ICTV_ranks)*['NA']}
        mapped=False
        # iterate from most specific rank backwards
        for i in range(1, len(c2c_dict[contig]['ranks'])+1):
            if mapped:
                break
            # use negative index once, but ensure lineage has that element
            rank_idx = -i
            if c2c_dict[contig]['ranks'][rank_idx] in ICTV_ranks:
                # ensure lineage is long enough to have the corresponding element
                if len(c2c_dict[contig]['lineage']) < i:
                    # no taxid available at this depth; skip
                    continue
                mapped=True
                taxid=c2c_dict[contig]['lineage'][rank_idx]
                
                if taxid in ncbi2ictv:
                    # ensure there is data to compute LCAs
                    if not ncbi2ictv[taxid].get('ictv') or not ncbi2ictv[taxid].get('ncbi'):
                        continue
                    ictv_lineage=find_LCA(ncbi2ictv[taxid]['ictv'])
                    ncbi_lineage=find_LCA(ncbi2ictv[taxid]['ncbi'])
                    ncbi_tmp=find_LCA(ncbi2ictv[taxid]['ncbi_ranks'])
                    ncbi_ranks=ncbi_tmp[:len(ncbi_lineage)+1]
                    
                    for rank in ictv_lineage:
                        ICTV_rank=ICTV_ranks[ictv_lineage.index(rank)]
                        if ICTV_rank in ncbi_ranks:
                            output_dict[contig]['names'][ICTV_ranks.index(ICTV_rank)]=ictv_lineage[ICTV_ranks.index(ICTV_rank)]
                           
    print('Writing output file...')
    with open(output_file, 'w') as outf:
        outf.write('SequenceID,realm,realm_score,subrealm,subrealm_score')
        for rank in ICTV_ranks[2:]:
            outf.write(f',{rank},{rank}_score')
        outf.write('\n')
        
        for contig in output_dict:
            outf.write(contig)
            for i in range(0, len(ICTV_ranks)):
                outf.write(f",{output_dict[contig]['names'][i]},{output_dict[contig]['scores'][i]}")
            outf.write('\n')
        
        
        
    return


if __name__=='__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Process ICTV output.')
    parser.add_argument('--ictv_file', type=str, required=True, help='Path to ICTV39_NCBI202412_per_accession.tsv file')
    parser.add_argument('--c2c_file', type=str, required=True, help='Path to 20241217_cat.c2c.names.txt file')
    parser.add_argument('--output_file1', type=str, required=True, help='Path to output file for direct challenge')
    parser.add_argument('--output_file2', type=str, required=True, help='Path to output file for mapped challenge')

    args = parser.parse_args()

    ncbi2ictv = make_ncbi2ictv_dict(args.ictv_file)
    c2c = make_c2c_dict(args.c2c_file)
    make_challenge_output_direct(c2c, args.output_file1)
    make_challenge_output_mapped(c2c, ncbi2ictv, args.output_file2)
