#!/bin/bash
###############################################################################
## header
    pipeline=0009_demultiplexing_by_barbell
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline -----------------------------------------------"
###############################################################################

    primer_file=$(grep my_F_primer $parameters | awk '{print $2}')
    grep ">" $primer_file | sed 's/>//g' | awk -F'_' '{print $1}' | sort | uniq  > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    cut -f 1,3 $primer_file | sed 's/\t/\n/g' > $wd/tmp/list.primers.txt	

    cp ${suppl_scripts}/0009_demultiplexing_by_barbell.sbatch \
        $wd/tmp/sbatch/0009_demultiplexing_by_barbell.sbatch
    sbatch ${wd}/tmp/sbatch/0009_demultiplexing_by_barbell.sbatch

    mkdir -p $wd/tmp/filters
    mkdir -p $wd/tmp/primers
    mkdir -p $wd/fastq
###############################################################################
    log "FINISHED : $pipeline -----------------------------------------------"
###############################################################################
## create primer files for custom demultiplexing
    # cat primers.tsv
        # mut2_9_F	AACCAAGACTCGCTGTGCCTAGTTCGGATTATCGAGACTGG	mut2_9_R	TTGATCCGTGTCGCTCAGAACCAAGATCTATGAAGTCGGCT
        # mut2_10_F	GAGAGGACAAAGGTTTCAACGCTTCGGATTATCGAGACTGG	mut2_10_R	TTCGCAACTTTGGAAACAGGAGAGGATCTATGAAGTCGGCT
        # mut2_11_F	TCCATTCCCTCCGATAGATGAAACCGGATTATCGAGACTGG	mut2_11_R	CAAAGTAGATAGCCTCCCTTACCTGATCTATGAAGTCGGCT

    # cut -f '1,2' primers.tsv | sed '/^$/d' | sed 's/mut/>mut/g' | sed 's/\t/\n/g' > F_primers.txt
    # cut -f '3,4' primers.tsv | sed '/^$/d' | sed 's/mut/>mut/g' | sed 's/\t/\n/g' > R_primers.txt

    # awk '/^>/ {header = substr($1, 2);split(header,a,"_"); file = a[1] "_F.txt"} {print >> file}' F_primers.txt 
    # awk '/^>/ {header = substr($1, 2);split(header,a,"_"); file = a[1] "_R.txt"} {print >> file}' R_primers.txt
    # mv *_F.txt $wd/tmp/primers
    # mv *_R.txt $wd/tmp/primers

