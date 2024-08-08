#!/bin/bash
###############################################################################
## step-2: get the stat of fasta or fastq files
###############################################################################
if [ -f list.prophage_fasta.txt ] ; then 
    echo "filename	total_length	number	mean_length	longest	shortest	N_count	Gaps	N50	N50n	N70	N70n	N90	N90n" > results/0040_assembly/all_fasta_prophage_genomeStat.tab
    for file in $(cat list.prophage_fasta.txt ); do
        echo $file
        /home/groups/VEO/tools/assembly-stats/v1.0.1/build/assembly-stats \
        -u results/0040_assembly/all_fasta_prophage/$file.fasta \
        >> results/0040_assembly/all_fasta_prophage_genomeStat.tab
    done
fi
###############################################################################