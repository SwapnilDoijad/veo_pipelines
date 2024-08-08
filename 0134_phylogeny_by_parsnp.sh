#!/bin/bash
###############################################################################
echo "script 0134_phylogeny_by_parsnp started -----------------------------------------------------"
###############################################################################

    list=list.all_fasta.txt
    fasta_path=/home/xa73pav/projects/p_rabia_genome/data/all_fasta
    ( mkdir -p results/0134_phylogeny_by_parsnp/raw_files ) > /dev/null 2>&1
###############################################################################
## run parsnp

    # for i in $(cat $list); do 
    #     sed -i 's/-/_/g' $fasta_path/$i.fasta
    # done 

    echo "running parsnp program"
    /home/groups/VEO/tools/parsnp/v1.2/parsnp -r ! -c -d $fasta_path -p 80 -o results/0134_phylogeny_by_parsnp
    echo "parnsp finished, cleaning"
###############################################################################
echo "completed.... step-11 harvest suite ------------------------------------"
###############################################################################
