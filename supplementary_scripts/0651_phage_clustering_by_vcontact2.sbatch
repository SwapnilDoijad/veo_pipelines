#!/bin/bash
#SBATCH --job-name 0651_phage_clustering_by_vcontact2
#SBATCH --partition=long
#SBATCH --output results/0651_phage_clustering_by_vcontact2/tmp/slurm/%j.out
#SBATCH --error results/0651_phage_clustering_by_vcontact2/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
#-- Command section ------------------------

###############################################################################
# b08 annotation
###############################################################################
## installation steps
## conda create --name vcontact2_p310 python=3.10
## conda install -y -c bioconda vcontact2_p310 mcl blast diamond
###############################################################################
## file preparations
    list=list.prophage_fasta.txt
    # if [ -f list.my_fasta.txt ]; then 
    #     list=list.my_fasta.txt
    #     else
    #     echo "provide list file (for e.g. all)"
    #     echo "---------------------------------------------------------------------"
    #     ls list.*.txt | awk -F'.' '{print $2}'
    #     echo "---------------------------------------------------------------------"
    #     read l
    #     list=$(echo "list.$l.txt")
    # fi

    (mkdir results/0651_phage_clustering_by_vcontact2) > /dev/null 2>&1
    (mkdir results/0651_phage_clustering_by_vcontact2/raw_files) > /dev/null 2>&1
    wd=results/0651_phage_clustering_by_vcontact2

###############################################################################
## file preparations 

(rm -rf results/0651_phage_clustering_by_vcontact2/raw_files/*.tmp) > /dev/null 2>&1
(rm -rf results/0651_phage_clustering_by_vcontact2/raw_files/proteins.faa) > /dev/null 2>&1
(rm -rf results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv) > /dev/null 2>&1

if [ ! -f results/0651_phage_clustering_by_vcontact2/raw_files/proteins.faa ] ; then 
    for i in $(cat $list); do
        (mkdir results/0651_phage_clustering_by_vcontact2/raw_files/$i) > /dev/null 2>&1
        faa_location=results/0083_annotation_prophage_by_pharokka/raw_files/$i

        grep ">" $faa_location/phanotate.faa | sed 's/>//g' | awk '{print $1}' \
        >> results/0651_phage_clustering_by_vcontact2/raw_files/$i.1.tmp

        grep ">" $faa_location/phanotate.faa | sed 's/>//g' | cut -f 2- -d ' ' | sed 's/ /_/g' | sed 's/\,/_/g' | sed "s/\'/_/g" \
        >> results/0651_phage_clustering_by_vcontact2/raw_files/$i.3.tmp

        total_cds=$(wc -l results/0651_phage_clustering_by_vcontact2/raw_files/$i.1.tmp | awk '{print $1}')
        for i2 in `seq $total_cds`; do 
            echo "$i" >> results/0651_phage_clustering_by_vcontact2/raw_files/$i.2.tmp
        done

        paste results/0651_phage_clustering_by_vcontact2/raw_files/$i.1.tmp \
        results/0651_phage_clustering_by_vcontact2/raw_files/$i.2.tmp \
        results/0651_phage_clustering_by_vcontact2/raw_files/$i.3.tmp \
        > results/0651_phage_clustering_by_vcontact2/raw_files/$i/$i.for_vcontact2.csv

        cat results/0651_phage_clustering_by_vcontact2/raw_files/$i/$i.for_vcontact2.csv >> results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv

        cat $faa_location/phanotate.faa >> results/0651_phage_clustering_by_vcontact2/raw_files/proteins.faa

        (rm -rf results/0651_phage_clustering_by_vcontact2/raw_files/$i ) > /dev/null 2>&1
    done
    sed -i '1 i\protein_id,contig_id,keywords' results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv
    sed -i 's/\t/,/g' results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv
fi


###############################################################################
## running vcontact2
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
    conda activate vcontact2_p310
    (mkdir $wd/raw_files/results) > /dev/null 2>&1

    echo "running vcontact2"
    vcontact2 \
    -r results/0651_phage_clustering_by_vcontact2/raw_files/proteins.faa \
    --db 'ProkaryoticViralRefSeq85-ICTV' \
    -p results/0651_phage_clustering_by_vcontact2/raw_files/for_vcontact2.csv \
    --c1-bin /home/groups/VEO/tools/anaconda3/bin/cluster_one-1.0.jar \
    -o results/0651_phage_clustering_by_vcontact2/raw_files/results \
    -t 80 

###############################################################################
exit



