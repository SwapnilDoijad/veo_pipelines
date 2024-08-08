#!/bin/bash
###############################################################################
# m005 atlas
###############################################################################
## installation date 2023.01.31
## doumentation 
## https://metagenome-atlas.readthedocs.io/en/latest/index.html
###############################################################################
## installation steps
## conda create --name atlas
## conda install --name atlas -c bioconda metagenome-atlas
###############################################################################
## installation steps
## conda create --name atlasenv python=3.8
## conda activate atlasenv
## conda install --name atlasenv mamba python=3.8
## mamba create -y -n atlasenv metagenome-atlas=2.14.2 mamba activate atlasenv
## mamba activate atlasenv
###############################################################################
echo "started... step-04 atlas: QC, assembly, annotatoin, bining -------------"
###############################################################################
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate atlasenv
    mamba init
    mamba activate atlasenv

    echo "provide path of the directory where fastq.gz file are located for e.g. (/home/xa73pav/projects/test_project/data/illumina/raw_reads)"
    read path_to_fastq

    echo "provide list file (for e.g. all)"
    echo "---------------------------------------------------------------------"
    ls list.*.txt | awk -F'.' '{print $2}'
    echo "---------------------------------------------------------------------"
    read l
    list=$(echo "list.$l.txt")

    (mkdir results/m00040_assembly) > /dev/null 2>&1
    (mkdir results/m00040_assembly/raw_files) > /dev/null 2>&1

###############################################################################
    echo "starting project"
    atlas init --db-dir databases $path_to_fastq
###############################################################################
