#!/bin/bash
###############################################################################
## step-00: tools, databases, paths, inputs and outputs
    pipeline=0003_download_SRA_from_NCBI_no_split
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    ## for automation, if the file is not present, then check if the list is provided by "-l" flag
        if  [ -f list.accession.txt ] ; then 
            list=list.accession.txt
            else
            echo "provide list file (for e.g. all)"
            echo "---------------------------------------------------------------------"
            ls list.*.txt | awk -F'.' '{print $2}'
            echo "---------------------------------------------------------------------"
            read l
            list=$(echo "list.$l.txt")
        fi

###############################################################################
## step-01: preparations
        (mkdir -p data/ncbi/raw_reads) > /dev/null 2>&1 ;

        create_directories_structure_1 $wd
        split_list $wd $list
        submit_jobs $wd $pipeline

###############################################################################
echo "script 0003_download_SRA_from_NCBI has ended ---------------------------------"
###############################################################################