#!/bin/bash
###############################################################################
## header 
    pipeline=0022_QC_of_nanopore_fastq_by_nanoplot
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : $pipeline --------------------------------"
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
    
    if [ -f tmp/parameters/files_in_data_directory.txt ]; then
        fastq_file_path=$(grep fastq tmp/parameters/files_in_data_directory.txt | awk '{print $NF}')
        else
        echo "provide fastq_file_path"
        read fastq_file_path
    fi

    (mkdir -p results/0022_QC_nanopore_by_nanoplot) > /dev/null 2>&1

###############################################################################
## run nanoplot
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate nanoplot_v1.41.3
    
    for i in $(cat $list ); do
        if [ ! -f results/0022_QC_nanopore_by_nanoplot/raw_files/$i/NanoStats.txt ] ; then
            log "STARTED : nanoplot for $i"
            if [ -f $fastq_file_path/$i.fastq.gz ] ; then 
                NanoPlot -t 2 --fastq $fastq_file_path/$i.fastq.gz -o results/0022_QC_nanopore_by_nanoplot/raw_files/$i
                elif [ -f $fastq_file_path/$i.fastq ] ; then 
                NanoPlot -t 2 --fastq $fastq_file_path/$i.fastq -o results/0022_QC_nanopore_by_nanoplot/raw_files/$i
            fi
            else
            log "ALREADY FINISHED : nanoplot for $i"
        fi
    done

###############################################################################
## combine Number of reads and Total bases and Q12 and Q15
    if [ ! -f results/0022_QC_nanopore_by_nanoplot/QC_summary.txt ] ; then 
        echo -e "id\treads\tbases\tq15" > results/0022_QC_nanopore_by_nanoplot/QC_summary.txt
        for i in $( cat $list ) ; do
            reads=$(grep "Number of reads:" results/0022_QC_nanopore_by_nanoplot/raw_files/$i/NanoStats.txt | awk '{print $NF}')
            bases=$(grep "Total bases:" results/0022_QC_nanopore_by_nanoplot/raw_files/$i/NanoStats.txt | awk '{print $NF}')
            q15=$(grep ">Q15:" results/0022_QC_nanopore_by_nanoplot/raw_files/$i/NanoStats.txt | awk -F'\t' '{print $2, $3, $4}' )
            echo -e "$i\t$reads\t$bases\t$q15" >> results/0022_QC_nanopore_by_nanoplot/QC_summary.txt 
        done 
    fi
###############################################################################
	log "ENDED : 0022_QC_of_nanopore_fastq_by_nanoplot --------------------------------"
###############################################################################