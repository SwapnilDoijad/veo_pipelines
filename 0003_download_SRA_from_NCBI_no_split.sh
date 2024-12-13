#!/bin/bash
###############################################################################
## step-00: tools, databases, paths, inputs and outputs
    pipeline=0003_download_SRA_from_NCBI_no_split
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

        ## Function to display script usage
        usage() {
            echo "---------------------------------------------------------------------"
            echo "Usage: bash 0003_download_SRA_from_NCBI.sh -l <list.my_accession.txt>"
            echo ""
            echo "Options:"
            echo "      -l <list.accession.txt> : Specify the input text file"
            echo ""
            echo "The list.my_accession.txt should contain accession numbers, each on seperat file"
            echo "      for e.g., cat list.accession.txt"
            echo "      SRR25161641"
            echo "      SRR25147113"
            echo "      SRR25147071"
            echo "      ..."
            echo "---------------------------------------------------------------------"
            exit 1
            }

    ## for automation, if the file is not present, then check if the list is provided by "-l" flag
        if  [ -f list.accession.txt ] ; then 
            list=list.accession.txt
            elif [ -f list.accession.txt ] ; then  
                # Parse command-line arguments
                while getopts ":l:" opt; do
                    case $opt in
                        f)
                        list=$OPTARG
                        ;;
                        \?)
                        echo "Invalid option: -$OPTARG"
                        usage
                        ;;
                        :)
                        echo "Option -$OPTARG requires an argument."
                        usage
                        ;;
                    esac
                done
            else
            usage
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