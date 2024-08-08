#!/bin/bash
###############################################################################
## header 
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: 0050_genome_assembly_QC_by_quast --------------------"
###############################################################################
## step-01: preparation
    pipeline=0050_genome_assembly_QC_by_quast
    wd=results/$pipeline

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    fasta_path=$(grep -v '^#' tmp/parameters/$pipeline.txt | sed 's/^[ \t]*//')
    create_directories_structure_1 $wd
    split_list $wd $list


###############################################################################
## step-00: run QUAST

    for sublist in $( ls $wd/tmp/lists/ ) ; do
        sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0050_genome_assembly_QC_by_quast.sbatch \
        | sed "s#XYZ#$fasta_path#g" \
        > $wd/tmp/sbatch/0050_genome_assembly_QC_by_quast.$sublist.sbatch
        sbatch $wd/tmp/sbatch/0050_genome_assembly_QC_by_quast.$sublist.sbatch > /dev/null 2>&1
        log "SUBMITTED : batch $sublist for quast "
    done 

    echo "Assembly	# contigs (>= 0 bp)	# contigs (>= 1000 bp)	# contigs (>= 5000 bp)	# contigs (>= 10000 bp)	# contigs (>= 25000 bp)	# contigs (>= 50000 bp)	Total length (>= 0 bp)	Total length (>= 1000 bp)	Total length (>= 5000 bp)	Total length (>= 10000 bp)	Total length (>= 25000 bp)	Total length (>= 50000 bp)	# contigs	Largest contig	Total length	GC (%)	N50	N90	auN	L50	L90	# N's per 100 kbp" > $wd/summary.tsv
    for i in $(cat $list); do 
        while [ ! -f "$wd/raw_files/$i/transposed_report.tsv.tmp" ]; do
            log "WAITING : quast to finish $i"
            sleep 60
        done
        log "FINISHED : quast for $i"
        cat $wd/raw_files/$i/transposed_report.tsv.tmp >> $wd/summary.tsv ;
    done 

###############################################################################
log "ENDED : 0050_genome_assembly_QC_by_quast ----------------------"
###############################################################################
