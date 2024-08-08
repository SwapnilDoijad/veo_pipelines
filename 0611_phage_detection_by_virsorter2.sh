#!/bin/bash
###############################################################################
## m012 virsorter2
###############################################################################
## installation steps
## conda create --name virsorter2 -c conda-forge -c bioconda virsorter=2
## virsorter setup -d /work/groups/VEO/databases/virsorter2 -j 4
###############################################################################
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate virsorter2

    if [ -f list.my_fasta.txt ]; then 
        list=list.my_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi
    
    (mkdir -p results/b061_virsorter2/raw_files) > /dev/null 2>&1
###############################################################################
    for fasta in $(cat $list); do
        echo "virsorter2 running for $fasta"
        (mkdir results/b061_virsorter2/raw_files/$fasta ) > /dev/null 2>&1
        virsorter run -w results/b061_virsorter2/raw_files/$fasta/ \
        -i /work/groups/VEO/databases/ncbi/genomes/refseq/bacteria/$fasta/"$fasta"*_genomic.fna \
        -d /work/groups/VEO/databases/virsorter2 --min-length 1500 -j 100 all
    done
###############################################################################