#!/bin/bash
###############################################################################
echo "started... 0653_phage_clustering_by_mmseq2 -------------------------------------"
###############################################################################
##step-01: file and directory preparations
    if [ -f list.prophage_fasta.txt ]; then 
        list=list.prophage_fasta.txt
        l=prophage_fasta
        elif [ -f list.bacterial_fasta.txt ] ; then 
        list=list.bacterial_fasta.txt
        l=bacterial_fasta
        else
        echo "provide genome list file (for e.g. all)"
        echo "-------------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g'
        echo "-------------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    #------------------------------------------------------------------------------
    (mkdir results )> /dev/null 2>&1
    (mkdir results/0653_phage_clustering_by_mmseq2)> /dev/null 2>&1
    (mkdir results/0653_phage_clustering_by_mmseq2/tmp)> /dev/null 2>&1
    (rm results/0653_phage_clustering_by_mmseq2/summary.tsv)> /dev/null 2>&1

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate mmseq2_v14.7e284

    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep prophage_fasta result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi
###############################################################################
##step-02: run mmseq

    gzip -c $fasta_file_path/*.fasta > results/0653_phage_clustering_by_mmseq2/tmp/fasta.gz 

    echo "running mmseqs with stict cutoffs (-c 0.10 --min-seq-id 0.97)"
    mkdir results/0653_phage_clustering_by_mmseq2/10_97
    mmseqs easy-linclust \
    results/0653_phage_clustering_by_mmseq2/tmp/fasta.gz \
    mmseq_out results/0653_phage_clustering_by_mmseq2/tmp \
    -c 0.10 --min-seq-id 0.97 --cov-mode 1 --alignment-mode 3 --threads 80
    mv mmseq_out* results/0653_phage_clustering_by_mmseq2/10_97/
    number_of_clusters=$(awk '{print $1}' results/0653_phage_clustering_by_mmseq2/10_97/mmseq_out_cluster.tsv | sort -u | wc -l )
    echo "$number_of_clusters clusters found for 10% coverage and 97% nucleotide identity" >> results/0653_phage_clustering_by_mmseq2/summary.tsv

    echo "running mmseqs with stict cutoffs (-c 0.8 --min-seq-id 0.97)"
    mkdir results/0653_phage_clustering_by_mmseq2/80_97
    mmseqs easy-linclust \
    results/0653_phage_clustering_by_mmseq2/tmp/fasta.gz \
    mmseq_out results/0653_phage_clustering_by_mmseq2/tmp \
    -c 0.8 --min-seq-id 0.97 --cov-mode 1 --alignment-mode 3 --threads 80
    mv mmseq_out* results/0653_phage_clustering_by_mmseq2/80_97/
    number_of_clusters=$(awk '{print $1}' results/0653_phage_clustering_by_mmseq2/80_97/mmseq_out_cluster.tsv | sort -u | wc -l )
    echo "$number_of_clusters clusters found for 80% coverage and 97% nucleotide identity" >> results/0653_phage_clustering_by_mmseq2/summary.tsv

    echo "running mmseqs with stict cutoffs (-c 0.65 --min-seq-id 0.80)"
    mkdir results/0653_phage_clustering_by_mmseq2/65_80
    mmseqs easy-linclust \
    results/0653_phage_clustering_by_mmseq2/tmp/fasta.gz \
    mmseq_out results/0653_phage_clustering_by_mmseq2/tmp \
    -c 0.65 --min-seq-id 0.80 --cov-mode 1 --alignment-mode 3 --threads 80
    mv mmseq_out* results/0653_phage_clustering_by_mmseq2/65_80/
    number_of_clusters=$(awk '{print $1}' results/0653_phage_clustering_by_mmseq2/65_80/mmseq_out_cluster.tsv | sort -u | wc -l )
    echo "$number_of_clusters clusters found for 65% coverage and 80% nucleotide identity" >> results/0653_phage_clustering_by_mmseq2/summary.tsv

    echo "running mmseqs with stict cutoffs (-c 0.50 --min-seq-id 0.65)"
    mkdir results/0653_phage_clustering_by_mmseq2/50_65
    mmseqs easy-linclust \
    results/0653_phage_clustering_by_mmseq2/tmp/fasta.gz \
    mmseq_out results/0653_phage_clustering_by_mmseq2/tmp \
    -c 0.50 --min-seq-id 0.65 --cov-mode 1 --alignment-mode 3 --threads 80
    mv mmseq_out* results/0653_phage_clustering_by_mmseq2/50_65/
    number_of_clusters=$(awk '{print $1}' results/0653_phage_clustering_by_mmseq2/50_65/mmseq_out_cluster.tsv | sort -u | wc -l )
    echo "$number_of_clusters clusters found for 50% coverage and 65% nucleotide identity" >> results/0653_phage_clustering_by_mmseq2/summary.tsv

    echo "running mmseqs with stict cutoffs (-c 0.30 --min-seq-id 0.50)"
    mkdir results/0653_phage_clustering_by_mmseq2/30_50
    mmseqs easy-linclust \
    results/0653_phage_clustering_by_mmseq2/tmp/fasta.gz \
    mmseq_out results/0653_phage_clustering_by_mmseq2/tmp \
    -c 0.30 --min-seq-id 0.50 --cov-mode 1 --alignment-mode 3 --threads 80
    mv mmseq_out* results/0653_phage_clustering_by_mmseq2/30_50/
    number_of_clusters=$(awk '{print $1}' results/0653_phage_clustering_by_mmseq2/30_50/mmseq_out_cluster.tsv | sort -u | wc -l )
    echo "$number_of_clusters clusters found for 30% coverage and 50% nucleotide identity" >> results/0653_phage_clustering_by_mmseq2/summary.tsv

###############################################################################
## step-03: send report by email (with attachment)

    echo "sending email"
    user=$(whoami)
    user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0653_phage_clustering_by_mmseq2.py -e $user_email

    deactivate
###############################################################################
echo "finished... 0653_phage_clustering_by_mmseq2 -------------------------------------"
###############################################################################