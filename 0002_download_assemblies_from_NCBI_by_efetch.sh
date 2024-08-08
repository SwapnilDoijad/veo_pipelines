#!/bin/bash
###############################################################################
echo "script 0002 download assemblies from NCBI started ------------------------------" 
###############################################################################
# step-01:  
    echo "provide list of accession (for e.g. all)"
    echo "---------------------------------------------------------------------"
    ls list.*.txt | awk -F'.' '{print $2}'
    echo "---------------------------------------------------------------------"
    read l
    list=$(echo "list.$l.txt")

    (mkdir -p results/0040_assembly/all_fasta ) > /dev/null 2>&1
    
###############################################################################
for i in $(cat $list);do
    echo $i

    /home/groups/VEO/tools/edirect/esearch -db sra -query PRJNA816463 | efetch -format runinfo | cut -d ',' -f 1 | grep SRR > srr_ids.txt
    #efetch -db nucleotide -id $i -format fasta > results/0040_assembly/all_fasta/$i.fasta

    /home/groups/VEO/tools/edirect/esearch -db assembly -query "$i" | \
    /home/groups/VEO/tools/edirect/efetch -format docsum  > tmp.tmp #| \
    #/home/groups/VEO/tools/edirect/xtract -pattern DocumentSummary -element FtpPath_RefSeq > tmp.tmp

    link=$(cat tmp.tmp | grep FtpPath_Assembly_rpt | awk -F'>' '{print $2}' | awk -F'<' '{print $1}' | sed 's/_assembly_report.txt//g' ) 

    download_link=$(echo "$link"_genomic.fna.gz )

    echo "downlaoding $download_link"

    wget $download_link

    name=$(echo $download_link | awk -F'/' '{print $NF}' )

    echo $name

    gzip -d $name

done

#rm tmp.tmp
###############################################################################
echo "script 0002 download assemblies from NCBI ended --------------------------------" 
###############################################################################
exit

