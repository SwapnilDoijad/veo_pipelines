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
        echo "      -l <list.my_accession.txt> : Specify the input text file"
        echo ""
        echo "The list.my_accession.txt should contain accession numbers, each on a separate line"
        echo "      for e.g., cat list.my_accession.txt"
        echo "      SRR25161641"
        echo "      SRR25147113"
        echo "      SRR25147071"
        echo "      ..."
        echo "---------------------------------------------------------------------"
        exit 1
    }

    ## for automation, if the file is not present, then check if the list is provided by "-l" flag
    if [ ! -f list.my_accession.txt ]; then
        # Parse command-line arguments
        while getopts ":l:" opt; do
            case $opt in
                l)
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
        list="list.my_accession.txt"
    fi

    echo "my list is $list"



###############################################################################
## step-01: preparations
    (mkdir -p /work/groups/VEO/databases/fastqs/raw_files) > /dev/null 2>&1 ;
    (mkdir -p tmp/lists) > /dev/null 2>&1 ;
    (mkdir -p tmp/slurm) > /dev/null 2>&1 ;
    (mkdir -p tmp/sbatch) > /dev/null 2>&1 ;

    (rm tmp/lists/*.* ) > /dev/null 2>&1 ;
    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 1 ))
    split -l "$lines_per_part" -a 3 -d "$list" list.0003b_download_SRA_from_NCBI_no_split_
    mv list.0003b_download_SRA_from_NCBI_no_split_* tmp/lists/

###############################################################################
echo "script 0003_download_SRA_from_NCBI has started ---------------------------------"
###############################################################################
## step-02: running the script
    ## faster download is possible through parallel-fastq-dump

    for sublists in $( ls tmp/lists/ ) ; do
        sublist=$(echo $sublists | awk -F'/' '{print $NF}')
        sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0003b_download_SRA_from_NCBI_no_split.sbatch \
        > tmp/sbatch/0003b_download_SRA_from_NCBI_no_split.$sublist.sbatch
        sbatch tmp/sbatch/0003b_download_SRA_from_NCBI_no_split.$sublist.sbatch
    done 

    # for SRA_id in $(cat $list); do
    #     if [ ! -f /work/groups/VEO/databases/fastqs/raw_files/$SRA_id/"$SRA_id".sra ] ; then
    #         ## Download
    #         echo "downloading $SRA_id"

        ## by NCBI sratoolkit (slow)
        # ( $tool_path/prefetch $SRA_id --output-directory /work/groups/VEO/databases/fastqs/raw_files ) > /dev/null 2>&1 ;

        # ## Conversion
        # echo "converting SRA to fastq $SRA_id"
        # ( $tool_path/fastq-dump --outdir /home/swapnil/ncbi/fastq/ --split-files /home/swapnil/ncbi/public/sra/$SRA_id.sra ) > /dev/null 2>&1 ;

        # ## Check for fastq pair
        # if [ -f /home/swapnil/ncbi/fastq/"$SRA_id"_1.fastq ] && [ -f /home/swapnil/ncbi/fastq/"$SRA_id"_2.fastq ] ; then
        #     cp /home/swapnil/ncbi/fastq/"$SRA_id"_1.fastq /work/groups/VEO/databases/fastqs ;
        #     (gzip /work/groups/VEO/databases/fastqs/"$SRA_id"_1.fastq) > /dev/null 2>&1 ;
        #     rm /home/swapnil/ncbi/fastq/"$SRA_id"_1.fastq ;
        #     cp /home/swapnil/ncbi/fastq/"$SRA_id"_2.fastq /work/groups/VEO/databases/fastqs/ ;
        #     (gzip /work/groups/VEO/databases/fastqs/"$SRA_id"_2.fastq) > /dev/null 2>&1 ;
        #     rm /home/swapnil/ncbi/fastq/"$SRA_id"_2.fastq ;
        #     rm /home/swapnil/ncbi/public/sra/$SRA_id.sra ;
        # fi
    #     else
    #         echo "$SRA_id already dowloaded"
    #     fi
    # done
###############################################################################
echo "script 0003_download_SRA_from_NCBI has ended ---------------------------------"
###############################################################################