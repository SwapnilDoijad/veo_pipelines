###############################################################################
## output
# 1 Percentage of fragments covered by the clade rooted at this taxon
# 2 Number of fragments covered by the clade rooted at this taxon
# 3 Number of fragments assigned directly to this taxon
# 4 A rank code, indicating (U)nclassified, (R)oot, (D)omain, (K)ingdom, (P)hylum, (C)lass, (O)rder, (F)amily, (G)enus, or (S)pecies. Taxa that are not at any of these 10 ranks have a rank code that is formed by using the rank code of the closest ancestor rank with a number indicating the distance from that rank. E.g., "G2" is a rank code indicating a taxon is between genus and species and the grandparent taxon is at the genus rank.
# 5 NCBI taxonomic ID number
# 6 Indented scientific name
###############################################################################
#  /home/groups/VEO/tools/kraken2/v2.1.2-build
#  /home/groups/VEO/tools/kraken2/v2.1.2-inspect
###############################################################################
## preliminary file preparations

    if [ -f list.my_fasta.txt ]; then 
        list=list.my_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    echo "Classification based on fasta (f) or raw reads (r) or filted-reads (s)"
    read input_file_type
    sfx=$(echo _"$input_file_type")
    if [  "$input_file_type" == "r" ] || [  "$input_file_type" == "s" ] ; then 
        echo "raw data path? (for e.g. /media/swapnil/network/reads_database/p_Entb_Germany)"
        read path
    fi

    if [ -f result_summary.read_me.txt ]; then
        fastq_file_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fastq_file_path"
        read fastq_file_path
    fi

    (mkdir -p results/0062_identification_kraken2"$sfx"/raw_files ) > /dev/null 2>&1
    path1=results/0062_identification_kraken2"$sfx"
    path2=results/0062_identification_kraken2"$sfx"/raw_files
###############################################################################
## run kraken2
    if [  "$input_file_type" == "f" ] ; then 
        for F1 in $(cat $list ); do
            echo "running kraken2 (fasta) for $F1"
            ( mkdir results/0062_identification_kraken2"$sfx"/raw_files/$F1 ) > /dev/null 2>&1  
            ( /home/groups/VEO/tools/kraken2/v2.1.2/kraken2 --db /work/groups/VEO/databases/kraken2/v20180901 --threads 20 --report $path2/$F1/report.txt --use-names results/0040_assembly/all_fasta/$F1.fasta ) > /dev/null 2>&1 
            #( kraken2 --db /work/groups/VEO/databases/kraken2/v20180901 --threads 8 --unclassified-out $path2/$F1/unclassified.txt  --classified-out $path2/$F1/classified.txt --report $path2/$F1/report.txt --use-names --output $path2/$F1/results.txt results/0040_assembly/all_fasta/$F1.fasta ) > /dev/null 2>&1 
            #gzip -c $path2/$F1/"unclassified#".fastq > $path2/$F1/"unclassified#".fastq.gz
            #gzip -c $path2/$F1/"classified#".fastq > $path2/$F1/"classified#".fastq.gz
            A1=$(awk -F'\t' ' $4=="S" {print $0}' $path2/$F1/report.txt | head -1 | sed 's/\t                /\t/g')
            echo $F1 $A1 >> $path1/report.csv
        done
        
        elif [ "$input_file_type" == "r" ] ; then
        for F1 in $(cat $list ); do
            echo "running kraken2 (raw_reads) for $F1"
            ( mkdir results/0062_identification_kraken2"$sfx"/raw_files/$F1 ) > /dev/null 2>&1 

            ( /home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
            --db /work/groups/VEO/databases/kraken2/v20180901 \
            --threads 20 \
            --report $path2/$F1/report.txt \
            --use-names \
            --paired $fastq_file_path/"$F1"_*R1*.gz $fastq_file_path/"$F1"_*R2*.gz ) > /dev/null 2>&1

            #( kraken2 --db /work/groups/VEO/databases/kraken2/v20180901 --threads 8 --unclassified-out $path2/$F1/"unclassified#".fastq --classified-out $path2/$F1/"$F1"_"classified#".fastq --report $path2/$F1/report.txt --use-names --output $path2/$F1/results.txt --paired $path/data/illumina/final_reads/"$F1"_*R1*.gz $path/data/illumina/final_reads/"$F1"_*R2*.gz ) > /dev/null 2>&1 
            #gzip -c $path2/$F1/"unclassified#".fastq > $path2/$F1/"unclassified#".fastq.gz
            #gzip -c $path2/$F1/"classified#".fastq > $path2/$F1/"classified#".fastq.gz
            A1=$(awk -F'\t' ' $4=="S" {print $0}' $path2/$F1/report.txt | head -1 | sed 's/\t                /\t/g')
            echo $F1 $A1 >> $path1/report.csv
        done
        
        elif [  "$input_file_type" == "s" ] ; then
        for F1 in $(cat $list ); do
            echo "running kraken2 (filtered_reads) for $F1"
            ( mkdir results/0062_identification_kraken2"$sfx"/raw_files/$F1 ) > /dev/null 2>&1 
            ( /home/groups/VEO/tools/kraken2/v2.1.2/kraken2 --db /work/groups/VEO/databases/kraken2/v20180901 --threads 20 --report $path2/$F1/report.txt --use-names --paired $path/results/02_filtered_reads/$F1/"$F1"_R1_001.filtered_paired.fastq.gz $path/results/02_filtered_reads/$F1/"$F1"_R2_001.filtered_paired.fastq.gz ) > /dev/null 2>&1 
            #( kraken2 --db /work/groups/VEO/databases/kraken2/v20180901 --threads 8 --unclassified-out $path2/$F1/"unclassified#".fastq  --classified-out $path2/$F1/"$F1"_"classified#".fastq --report $path2/$F1/report.txt --use-names --output $path2/$F1/results.txt --paired $path/results/02_filtered_reads/$F1/"$F1"_R1_001.filtered_paired.fastq.gz $path/results/02_filtered_reads/$F1/"$F1"_R2_001.filtered_paired.fastq.gz ) > /dev/null 2>&1 
            #gzip -c $path2/$F1/"unclassified#".fastq > $path2/$F1/"unclassified#".fastq.gz
            #gzip -c $path2/$F1/"classified#".fastq > $path2/$F1/"classified#".fastq.gz
            A1=$(awk -F'\t' ' $4=="S" {print $0}' $path2/$F1/report.txt | head -1 | sed 's/\t                /\t/g')
            echo $F1 $A1 >> $path1/report.csv
        done
    fi
###############################################################################
exit 

/home/groups/VEO/tools/kraken2/v2.1.2/kraken2 --db /work/groups/VEO/databases/kraken2/v20180901 --threads 40 --report results/132.report.txt --output results/132.out.txt --use-names results/0040_assembly/raw_files/132/assembly.fasta 