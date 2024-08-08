#!/bin/bash
###############################################################################
## step-00: tools, databases, paths, inputs and outputs

    tool_path=/home/groups/VEO/tools/sratoolkit/v3.0.1/bin

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
###############################################################################
echo "script 0003_download_SRA_from_NCBI has started ---------------------------------"
###############################################################################
## step-02: running the script
        for F1 in $(cat $list); do
            if [ ! -f data/ncbi/raw_reads/"$F1"_*.fastq ] ; then
                ## Download
                echo "downloding $F1"
                ( $tool_path/prefetch $F1 ) > /dev/null 2>&1 ;
                ## Conversion
                echo "converting SRA to fastq $F1"
                ( $tool_path/fastq-dump --outdir /home/swapnil/ncbi/fastq/ --split-files /home/swapnil/ncbi/public/sra/$F1.sra ) > /dev/null 2>&1 ;

                ## Check for fastq pair
                if [ -f /home/swapnil/ncbi/fastq/"$F1"_1.fastq ] && [ -f /home/swapnil/ncbi/fastq/"$F1"_2.fastq ] ; then
                    cp /home/swapnil/ncbi/fastq/"$F1"_1.fastq data/ncbi/raw_reads ;
                    (gzip data/ncbi/raw_reads/"$F1"_1.fastq) > /dev/null 2>&1 ;
                    rm /home/swapnil/ncbi/fastq/"$F1"_1.fastq ;
                    cp /home/swapnil/ncbi/fastq/"$F1"_2.fastq data/ncbi/raw_reads/ ;
                    (gzip data/ncbi/raw_reads/"$F1"_2.fastq) > /dev/null 2>&1 ;
                    rm /home/swapnil/ncbi/fastq/"$F1"_2.fastq ;
                    rm /home/swapnil/ncbi/public/sra/$F1.sra ;
                fi
            else
                echo "$F1 already dowloaded"
            fi
        done
###############################################################################
echo "script 0003_download_SRA_from_NCBI has ended ---------------------------------"
###############################################################################