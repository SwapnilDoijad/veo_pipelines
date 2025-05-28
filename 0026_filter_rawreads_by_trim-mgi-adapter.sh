#!/bin/bash
###############################################################################
echo "script 0026_filter_rawreads_by_trim-mgi-adapter started --------------------------------------------"
###############################################################################
## step-01: preparations

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
        else
        echo "provide list file (for e.g. all)"
        ls list.*.txt | sed 's/ /\n/g'
        read l
        list=$(echo "list.$l.txt")
    fi
     
    if [ -f result_summary.read_me.txt ]; then
        fastq_file_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fastq_file_path"
        read fastq_file_path
    fi

    (mkdir -p results/0026_filter_rawreads_by_trim-mgi-adapter/filteredReads ) > /dev/null 2>&1
###############################################################################
## step-02: run trim-mgi-adapter 

for i in $(cat $list); do
    mkdir -p results/0026_filter_rawreads_by_trim-mgi-adapter/filteredReads/$i

    # /home/groups/VEO/tools/mgi-adapters/v20230521/bin/search-mgi-adapters \
    # -1 $fastq_file_path/$i*R1*.fastq.gz \
    # -2 $fastq_file_path/$i*R2*.fastq.gz \


    /home/groups/VEO/tools/mgi-adapters/v20230521/bin/trim-mgi-adapters \
    -1 $fastq_file_path/$i*R1*.fastq.gz \
    -2 $fastq_file_path/$i*R2*.fastq.gz \
    -p results/0026_filter_rawreads_by_trim-mgi-adapter/filteredReads/"$i"_R1_001.trim-mgi-adapters-filtered.fastq.gz \
    -q results/0026_filter_rawreads_by_trim-mgi-adapter/filteredReads/"$i"_R2_001.trim-mgi-adapters-filtered.fastq.gz
done

