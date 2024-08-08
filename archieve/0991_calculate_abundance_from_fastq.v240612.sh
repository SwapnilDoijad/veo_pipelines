###############################################################################
## header and preparation
    pipeline=0991_calculate_abundance_from_fastq
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    create_directories_structure_1 $wd
    subsampling=no
    QC=10
    # subsamples_list=( 1000000 2000000 3000000 4000000 )

###############################################################################   
# ## step-01: create barcode files 
#     if [ ! -f list.barcodes_all.RC.txt ] ; then 
#         ( rm list.barcodes_F.fasta  ) > /dev/null 2>&1
#         ( rm list.barcodes_R.fasta  ) > /dev/null 2>&1
#         tail -n +2 tmp/parameters/$pipeline.my_barcode.txt | while read -r line; do
#             id=$(echo $line | awk '{print $2}' )
#             F_primer=$(echo $line | awk '{print $4}' )
#             R_primer=$(echo $line | awk '{print $5}' )
#             echo ">$id"_F >> list.barcodes_F.fasta
#             echo "$F_primer" >> list.barcodes_F.fasta
#             echo ">$id"_R >> list.barcodes_R.fasta
#             echo "$R_primer" >> list.barcodes_R.fasta
#         done 

#         python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/reverse_complement.py \
#         -i list.barcodes_F.fasta -o list.barcodes_F_RC.fasta

#         python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/reverse_complement.py \
#         -i list.barcodes_R.fasta -o list.barcodes_R_RC.fasta

#         cat list.barcodes_F.fasta list.barcodes_R.fasta | grep -v ">" > list.barcodes_all.FR.txt
#         cat list.barcodes_R_RC.fasta list.barcodes_F_RC.fasta  | grep -v ">" > list.barcodes_all.RC.txt

#         #@Swapnil, work out unique barcodes, to avoid repetition in the extraction and other downstream process
#         # cat list.barcodes_F.fasta list.barcodes_R.fasta | grep -v ">" | sort | uniq  > list.barcodes_all.FR.uniq.txt ## so that there should not be repetition in the extraction and other downstream process 
#         # cat list.barcodes_R_RC.fasta list.barcodes_F_RC.fasta  | grep -v ">" | sort | uniq > list.barcodes_all.RC.uniq.txt ## so that there should not be repetition in the extraction and other downstream process 

#         paste list.barcodes_all.FR.txt list.barcodes_all.RC.txt | sed 's/\t/\./g' > tmp.tmp
#         awk 'NR>1 {print $2}' tmp/parameters/$pipeline.my_barcode.txt > tmp2.tmp
#         awk 'NR>1 {print $2}' tmp/parameters/$pipeline.my_barcode.txt >> tmp2.tmp
#         paste tmp.tmp tmp2.tmp > list.barcodes.names.txt 
#         rm tmp.tmp 
#         rm tmp2.tmp
#         else
#         log "ALREADY FINISHED : creating barcode files"
#     fi 

###############################################################################
## Combine all fastqs

    # if [ ! -f results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq ] ; then 
    #     for i in $(ls results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_files/pass/ ); do
    #         echo "$i"
    #         cat results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_files/pass/*.fastq \
    #         >> results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq
    #     done
    #     else
    #     log "ALREADY FINISHED : combining all fastqs"
    # fi 
    
    # if [ ! -f $wd/tmp/total_number_of_reads.txt ] ; then 
    #     echo "calculating total number of reads"
    #     lines=$(wc -l results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq | awk '{print $1}' )
    #     total_number_of_lines=$(( $lines / 4 ))
    #     echo "total number of reads in all_combined.fastq $total_number_of_lines" > $wd/tmp/total_number_of_reads.txt
    #     else
    #     log "ALREADY FINISHED : total number of reads"
    # fi 

    total_number_of_reads=$(cat $wd/tmp/total_number_of_reads.txt)
    # echo "total_number_of_reads : $total_number_of_reads"

############################################################################### 
## subsampling

    if [ "$subsampling" == "no" ] ; then 
        subsamples=$total_number_of_reads
        elif [ "$subsampling" == "yes" ] ; then
        subsamples=${subsamples_list[@]}
        else
        echo "provide subsamples option"
    fi 

    # if [ ! -d $wd/subsampled ] ; then 
    #     (mkdir -p $wd/subsampled ) > /dev/null 2>&1
    #     source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 
    #     for subsample in "${subsamples[@]}"; do
    #         if [ ! -f $wd/subsampled/all_combined.subsampled_"$subsample".fastq ] ; then 
    #             log "subsampling for $subsample"
    #             rasusa -i results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq \
    #             -n $subsample -o $wd/subsampled/all_combined.subsampled_"$subsample".fastq -O u
    #         fi
    #     done

    #     else
    #     log "ALREADY FINISHED : subsampling"
    # fi 

###############################################################################
## extract_read-ids_from_fastq_if_pattern_present
    # file written is $wd/lists/list.$barcode.read_ids.$subsample.txt
    # file written is $wd/lists/list.$barcode.read_ids.only.$subsample.txt

    # for subsample in "${subsamples[@]}"; do
    #     # echo "extract_read-ids_from_fastq_if_pattern_present for $subsample"

    #     for barcode in $(cat list.barcodes_all.FR.txt); do 
    #         if [ ! -f $wd/tmp/lists/list.$barcode.read_ids.only.$subsample.txt ] ; then 
    #             log "creating and submitting sbatch for barcode $barcode"
    #             sed "s/ABC/$barcode/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_extract_read_ids.sbatch | sed "s/XYZ/$subsample/g" \
    #             > $wd/tmp/sbatch/extract_read_ids.$barcode.$subsample.sbatch
    #             sbatch $wd/tmp/sbatch/extract_read_ids.$barcode.$subsample.sbatch
    #         fi
    #     done
        
    #     for barcode_RC in $(cat list.barcodes_all.RC.txt); do 
    #         if [ ! -f $wd/tmp/lists/list.$barcode.read_ids.only.$subsample.txt ] ; then 
    #             log "creating and submitting sbatch for barcode_RC $barcode_RC"
    #             sed "s/ABC/$barcode_RC/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_extract_read_ids.sbatch | sed "s/XYZ/$subsample/g" \
    #             > $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch
    #             sbatch $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch
    #         fi
    #     done

    # done 

    ## first checkpoint for sbatch 
    # exit 
###############################################################################
## combine read ids from F, R and RC sequences, remove duplicates, also make a count
    # ( rm $wd/tmp/slurm/*.* ) > /dev/null 2>&1

    # if [ ! -f $wd/tmp/number_of_reads.read_ids.$subsample.tsv ] ; then 
    #     ( mkdir $wd/results/stat ) > /dev/null 2>&1
    #     for subsample in "${subsamples[@]}"; do
    #         log "for $subsample combining read ids, removing duplicates and counting "
    #         while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do
    #             num_of_barcode_FR=$(wc -l $wd/tmp/lists/list.$barcode_FR.read_ids.$subsample.txt | awk '{print $1}')
    #             num_of_barcode_RC=$(wc -l $wd/tmp/lists/list.$barcode_RC.read_ids.$subsample.txt | awk '{print $1}')
    #             num_of_new_reads_by_RC=$(diff \
    #             $wd/tmp/lists/list.$barcode_FR.read_ids.$subsample.txt \
    #             $wd/tmp/lists/list.$barcode_RC.read_ids.$subsample.txt \
    #             | grep "^>" | sed 's/^> //' | wc -l )

    #             cat $wd/tmp/lists/list.$barcode_FR.read_ids.$subsample.txt \
    #             $wd/tmp/lists/list.$barcode_RC.read_ids.$subsample.txt | \
    #             sort | uniq | sed 's/\@//g'> $wd/tmp/lists/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt

    #             non_duplicate_read_ids=$(($num_of_barcode_FR + $num_of_new_reads_by_RC ))

    #             echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids
    #             echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids \
    #             > $wd/tmp/lists/number_of_reads.$barcode.$barcode_RC.read_ids.$subsample.txt

    #             echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids \
    #             >> $wd/tmp/number_of_reads.read_ids.$subsample.tsv
    #         done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt" ## here, not using uniq as wish to cover all the samples. 

    #     done
    # fi 

###############################################################################
## get seperate fastqs for barcode/match
    ## out file is $wd/files/$barcode.$barcode_RC.$subsample.fastq"
 
    # ## 202405026
    # echo "swapnil, check /home/groups/VEO/scripts_for_users/supplementary_scripts/0992_get_reads.sbatch"
    # echo "its based on seqtk and exremly fast, make use of it next time "

    # ( mkdir $wd/files ) > /dev/null 2>&1 
    # for subsample in "${subsamples[@]}"; do
    #     while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do
    #         if [ ! -f $wd/files/$barcode.$barcode_RC.$subsample.fastq ] ; then 
    #             sed "s/ABC/$barcode/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_get_reads.sbatch \
    #             | sed "s/JKL/$barcode_RC/g" | sed "s/XYZ/$subsample/g" \
    #             > $wd/tmp/sbatch/0991_get_reads.$barcode.$barcode_RC.$subsample.sbatch
    #             sbatch $wd/tmp/sbatch/0991_get_reads.$barcode.$barcode_RC.$subsample.sbatch
    #         fi 
    #     done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
    # done 

    # ## second checkpoint for sbatch stop
    # # exit 

    # ## just for QC (run only when above loop is completely finished)
    #     number_of_reads=0
    #     for subsample in "${subsamples[@]}"; do
    #         while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do
    #             lines_in_file=$(wc -l $wd/files/$barcode.$barcode_RC.$subsample.fastq | awk '{print $1}')
    #             reads_in_file=$(( $lines_in_file / 4 ))
    #             # echo $barcode.$barcode_RC.$subsample : $reads_in_file
    #             total_number_of_reads=$(( $number_of_reads + $reads_in_file ))
    #             number_of_reads=$total_number_of_reads
    #         done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
    #     done 
    #     percentage_reads_got_binned=$(( $number_of_reads * 100 / $subsample ))
    #     echo "$percentage_reads_got_binned percentage ($number_of_reads/$subsample) of reads binned"
 
############################################################################### 
## filter reads (by chopper) for $QC

    # source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 

    # for subsample in "${subsamples[@]}"; do
    #     while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 
    #         if [ ! -f $wd/files/$barcode.$barcode_RC.$QC.$subsample.fastq ] ; then 
    #             log "STARTED : filter reads (by chopper) for $QC : $subsample "
    #             echo "$barcode && $barcode_RC for $subsample"
    #             cat $wd/files/$barcode.$barcode_RC.$subsample.fastq | chopper -q $QC > $wd/files/$barcode.$barcode_RC.$QC.$subsample.fastq
    #         fi 
    #     done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
    # done 
    # log "FINISHED : filter reads (by chopper) for $QC"
###############################################################################
## fastq2fasta for filtered reads 
    # for subsample in "${subsamples[@]}"; do
    #     while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 
    #         if [ ! -f $wd/files/$barcode.$barcode_RC.$QC.fastq.$subsample.fasta ] ; then 
    #             echo "$barcode && $barcode_RC for $subsample"
    #             python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_fastq2fasta.py \
    #             -i $wd/files/$barcode.$barcode_RC.$QC.$subsample.fastq \
    #             -o $wd/files/$barcode.$barcode_RC.$QC.fastq.$subsample.fasta

    #             lines_in_fasta10=$(wc -l $wd/files/$barcode.$barcode_RC.$QC.fastq.$subsample.fasta | awk '{print $1}')
    #             reads_in_fasta10=$(( $lines_in_fasta10 / 2 ))
    #             echo "reads in fasta $reads_in_fasta10"
    #         fi 
    #     done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
    # done
    # log "FINISHED : fastq2fasta for filtered reads"
###############################################################################
## QC: count the number of reads  
    # if [ ! -f $wd/tmp/total_number_of_reads.$QC.txt ] ; then 
    #     for subsample in "${subsamples[@]}"; do
    #         while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 

    #             number_of_reads_ids_in_FR=$(wc -l $wd/tmp/lists/list.$barcode.read_ids.$subsample.txt | awk '{print $1}')
    #             number_of_reads_ids_in_RC=$(wc -l $wd/tmp/lists/list.$barcode_RC.read_ids.$subsample.txt | awk '{print $1}')
    #             number_of_total_read_ids=$(( $number_of_reads_ids_in_FR + $number_of_reads_ids_in_RC )) ## here duplicates are not removed

    #             lines=$(wc -l $wd/files/$barcode.$barcode_RC.$subsample.fastq | awk '{print $1}' )
    #             non_duplicate_reads=$(( $lines / 4 ))

    #             lines_10=$(wc -l $wd/files/$barcode.$barcode_RC.$QC.$subsample.fastq | awk '{print $1}')
    #             reads_10=$(( $lines_10 / 4 ))

    #             lines_in_fasta10=$(wc -l $wd/files/$barcode.$barcode_RC.$QC.fastq.$subsample.fasta | awk '{print $1}')
    #             reads_in_fasta10=$(( $lines_in_fasta10 / 2 ))

    #             echo "$barcode && $barcode_RC : $number_of_total_read_ids $non_duplicate_reads $reads_10 $reads_in_fasta10" 
    #             echo "$barcode && $barcode_RC : $number_of_total_read_ids $non_duplicate_reads $reads_10 $reads_in_fasta10" >> $wd/tmp/total_number_of_reads.$QC.txt

    #         done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
    #     done
    # fi
    # log "FINISHED : QC: count the number of reads"
    ## checkpoint for reads
    # exit 
###############################################################################
## run blast  

    if [ ! -d $wd/databases ] ; then
        ( mkdir -p $wd/databases )
        ( mkdir -p $wd/blast_results )

        ## reformat multi-line fasta to one line fasta
        awk 'BEGIN {RS=">"; FS="\n"} NR>1 {printf ">%s\n", $1; for (i=2; i<=NF; i++) printf "%s", $i; print ""}' tmp/parameters/$pipeline.query_sequence.fasta \
        > tmp/parameters/$pipeline.query_sequence.2.fasta

        # create database for query sequence
        if [ ! -f $wd/databases/query_sequence.fasta.db.ndb ] ; then 
            /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
            -in tmp/parameters/$pipeline.query_sequence.2.fasta \
            -dbtype nucl -out $wd/databases/query_sequence.fasta.db
        fi 

        for subsample in "${subsamples[@]}"; do
            echo "subsample: $subsample"
            ##  blast each read against each query seqeunce 
                while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 
                    rm $wd/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.$subsample.tsv > /dev/null 2>&1
                    if [ ! -f $wd/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.$subsample.tsv ] ; then 
                        sed "s/ABC/$barcode/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_blast.sbatch \
                        | sed "s/JKL/$barcode_RC/g" | sed "s/XYZ/$subsample/g" | sed "s/DEF/$QC/g" \
                        > $wd/tmp/sbatch/blast.$barcode.$barcode_RC.$subsample.sbatch
                        sbatch $wd/tmp/sbatch/blast.$barcode.$barcode_RC.$subsample.sbatch
                    fi 
                done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
                
        done 
    fi
    log "FINISHED : run blast"

        # third stop for sbatch
        # exit 

    ## QC check for BLAST files 
        if [ ! -f $wd/tmp/blast.QC.tsv ] ; then 
            for subsample in "${subsamples[@]}"; do
                while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do  
                    number_of_lines=$(wc -l $wd/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.$subsample.tsv | awk '{print $1}' )
                    echo $subsample $barcode.$barcode_RC $number_of_lines
                    echo $subsample $barcode.$barcode_RC $number_of_lines >> $wd/tmp/blast.QC.tsv
                done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
            done
        fi

############################################################################### 
## count the numbers
    ## takes long (~OVERNIGHT) time 
    if [ ! -d  $wd/count  ] ; then 
        ( mkdir $wd/count ) > /dev/null 2>&1

        for subsample in "${subsamples[@]}"; do
            while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 
            if [ ! -f $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.tsv ] ; then 
                echo "creating and submitting sbatch for $barcode $barcode_RC"
                sed "s/barcode_RC/$barcode_RC/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_count_numbers.sbatch \
                | sed "s/barcode/$barcode/g" | sed "s/subsample/$subsample/g" | sed "s/QC/$QC/g" \
                > $wd/tmp/sbatch/count_numbers.$barcode.$barcode_RC.$subsample.sbatch
                sbatch $wd/tmp/sbatch/count_numbers.$barcode.$barcode_RC.$subsample.sbatch
            fi
            done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt" 
        done 
    fi

    ## fourth stop for sbatch
    # exit 
    for subsample in "${subsamples[@]}"; do
        if [ ! -f $wd/tmp/total_hits.$QC.$subsample.tsv ] ; then
            while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do  
                total_hits=$(awk 'NR>1 { sum += $2 } END { print sum }' $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.tsv)
                echo $barcode.$barcode_RC $total_hits | tee -a $wd/tmp/total_hits.$QC.$subsample.tsv
            done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
        fi
    done
    ## fifth stop for sbatch
    # exit 

###############################################################################
## summarise the count
    grep ">" tmp/parameters/$pipeline.query_sequence.2.fasta | sed 's/>//g' | sort -u | sed 's/ .*//g' > query.fasta.list

    for subsample in "${subsamples[@]}"; do
        if [ ! -f $wd/final_tables/all.$subsample.tsv  ] ; then 
            ( mkdir $wd/final_tables ) > /dev/null 2>&1 
            if [ ! -f $wd/final_tables/final_count.$subsample.tsv ] ; then 
                ( rm $wd/count/*.$QC.fastq.fasta.2.$subsample.txt ) > /dev/null 2>&1 
                while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 
                    echo $barcode.$barcode_RC > $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt
                    for id in $(cat query.fasta.list ) ; do 
                        V1=$(grep -w "$id" $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.tsv | awk '{print $2}' )
                        if [ ! -z $V1 ]; then
                            echo $V1 >> $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt
                            else
                            echo 0 >> $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt
                        fi 
                    done
                done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt" 

                sed '1i\ids' query.fasta.list > query.fasta.list.tmp
                paste query.fasta.list.tmp $wd/count/*.$QC.fastq.fasta.2.$subsample.txt \
                > $wd/final_tables/final_count.$subsample.tsv
                rm query.fasta.list.tmp 
            fi 


            ## QC check for number of blast_total_hits in best_hits and number of lines in count 
                if [ ! -f $wd/tmp/blast.QC.tmp ] ;then 
                    echo -e "subsample\tbarcode.barcode_RC\tblast_total_hits\tblast_specific_hits\tsample_hits" > $wd/tmp/blast.QC.tmp
                    for subsample in "${subsamples[@]}"; do
                        while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do  
                            blast_total_hits=$(wc -l $wd/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.$subsample.tsv | awk '{print $1}' )
                            blast_specific_hits=$(tail -n +2 $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt | awk '{sum+=$1} END {print sum}' ) 
                            sample_hits=$(wc -l $wd/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.tsv | awk '{print $1}' )
                            # echo brady $subsample $barcode.$barcode_RC $blast_total_hits $sample_hits
                            echo $subsample $barcode.$barcode_RC $blast_total_hits $blast_specific_hits $sample_hits >> $wd/tmp/blast.QC.tmp
                        done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
                    done 
                fi


            # barcodes2samples renaming
                
            while IFS= read -r line; do
                barcode=$(echo "$line" | awk '{print $1}')
                name=$(echo "$line" | awk '{print $2}')
                sed -i "s/$barcode/$name/g" $wd/final_tables/final_count.$subsample.tsv
                # sed -i "s/$barcode/$name/g" $wd/final_tables/final_count.rhizo.$subsample.tsv
            done < list.barcodes.names.txt
        fi

        if [ ! -f $wd/final_tables/all.$subsample.tsv ] ; then
            (rm $wd/final_tables/all.$subsample.tsv) > /dev/null 2>&1 
            ## create final table for Brady
            for header in $(head -1 $wd/final_tables/final_count.$subsample.tsv | sed 's/ids//g' | tr '\t' '\n' | sed '/^$/d' |  sort -u | sort -V ) ; do 
                echo $header
                awk -v header="$header" 'BEGIN {
                    FS="\t"
                    print header
                }
                NR==1 {
                    for (i=1; i<=NF; i++) {
                        if ($i == header) {
                            col[i] = 1
                        }
                    }
                }
                NR>1 {
                    row_sum = 0
                    for (i=1; i<=NF; i++) {
                        if (col[i]) {
                            row_sum += $i
                        }
                    }
                    printf "%s\n", row_sum
                }' $wd/final_tables/final_count.$subsample.tsv > $wd/final_tables/$header.tsv

                touch $wd/final_tables/all.$subsample.tsv
                paste $wd/final_tables/all.$subsample.tsv $wd/final_tables/$header.tsv > $wd/final_tables/all.tmp
                mv $wd/final_tables/all.tmp $wd/final_tables/all.$subsample.tsv
                rm $wd/final_tables/$header.tsv 
            done 

            sed '1i\ids' query.fasta.list > query.fasta.list.tmp
            paste query.fasta.list.tmp $wd/final_tables/all.$subsample.tsv > $wd/final_tables/all.2.tsv
            sed 's/\t\t/\t/g' $wd/final_tables/all.2.tsv > $wd/final_tables/all.$subsample.tsv 
            rm query.fasta.list.tmp
            rm $wd/final_tables/all.2.tsv
        fi

        # (rm $wd/final_tables/all.rhizo.$subsample.tsv) > /dev/null 2>&1 
        # ## create final table for Rhizo
        # for header in $(head -1 $wd/final_tables/final_count.rhizo.$subsample.tsv | sed 's/ids//g' | tr '\t' '\n' | sed '/^$/d' |  sort -u | sort -V ) ; do 
        #   echo $header
        #   awk -v header="$header" 'BEGIN {
        #       FS="\t"
        #       print header
        #   }
        #   NR==1 {
        #       for (i=1; i<=NF; i++) {
        #           if ($i == header) {
        #               col[i] = 1
        #           }
        #       }
        #   }
        #   NR>1 {
        #       row_sum = 0
        #       for (i=1; i<=NF; i++) {
        #           if (col[i]) {
        #               row_sum += $i
        #           }
        #       }
        #       printf "%s\n", row_sum
        #   }' $wd/final_tables/final_count.rhizo.$subsample.tsv > $wd/final_tables/$header.tsv

        #   touch $wd/final_tables/all.rhizo.$subsample.tsv
        #   paste $wd/final_tables/all.rhizo.$subsample.tsv $wd/final_tables/$header.tsv > $wd/final_tables/all.rhizo.tmp
        #   mv $wd/final_tables/all.rhizo.tmp $wd/final_tables/all.rhizo.$subsample.tsv
        #   rm $wd/final_tables/$header.tsv
        #   done 
        #   sed '1i\ids' query_rhizo.fasta.list > query_rhizo.fasta.list.tmp
        #   paste query_rhizo.fasta.list.tmp $wd/final_tables/all.rhizo.$subsample.tsv > $wd/final_tables/all.rhizo.2.tsv
        #   sed 's/\t\t/\t/g' $wd/final_tables/all.rhizo.2.tsv > $wd/final_tables/all.rhizo.$subsample.tsv 
        #   rm query_rhizo.fasta.list.tmp
        #   rm $wd/final_tables/all.rhizo.2.tsv
    done


###############################################################################
## create figure
    source /home/groups/VEO/tools/python/pandas/bin/activate

    for subsample in "${subsamples[@]}"; do
        echo "creating figure for $subsample for brady"
        ## first convert the table to percentage
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_table_to_percetage.py \
        -i $wd/final_tables/all.$subsample.tsv \
        -o $wd/final_tables/all.$subsample.perc.tsv
        ## create actual figure
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/stacked_column_chart.py \
        -i $wd/final_tables/all.$subsample.perc.tsv \
        -o $wd/final_tables/all.$subsample.perc.tsv.png
    done 

    # for subsample in "${subsamples[@]}"; do
    #   echo "creating figure for $subsample for rhizo"
    #   ## first convert the table to percentage
    #   python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_table_to_percetage.py \
    #   -i $wd/final_tables/all.rhizo.$subsample.tsv \
    #   -o $wd/final_tables/all.rhizo.$subsample.perc.tsv
    #   ## create actual figure
    #   python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/stacked_column_chart.py \
    #   -i $wd/final_tables/all.rhizo.$subsample.perc.tsv \
    #   -o $wd/final_tables/all.rhizo.$subsample.perc.tsv.png
    # done 

###############################################################################


## codes discarded or not using at moment 
###############################################################################
## pod5 to bam .fasta
    ## Comment: slow and time limit do now allow to use the GPU for long time. 
    #module load nvidia/cuda/11.7
        # ( mkdir data/pod5_basecalled_dorado_duplex_bam ) > /dev/null 2>&1
        # ( mkdir data/pod5_basecalled_dorado_duplex_bam/tmp ) > /dev/null 2>&1
        # ( mkdir data/pod5_basecalled_dorado_duplex_bam/bam_files ) > /dev/null 2>&1
        # for i in $( ls data/pod5 ); do 
        #   echo $i 
        #   cp data/pod5/$i data/pod5_basecalled_dorado_duplex_bam/tmp

        #   /home/groups/VEO/tools/dorado/v0.1/bin/dorado duplex -t 40 \
        #   /home/groups/VEO/tools/dorado/v0.1/models/dna_r10.4.1_e8.2_400bps_hac@v4.2.0 \
        #   data/pod5_basecalled_dorado_duplex_bam/tmp/ \
        #   > data/pod5_basecalled_dorado_duplex_bam/bam_files/$i.duplex.bam ;

        #   rm data/pod5_basecalled_dorado_duplex_bam/tmp/$i
        # done 
###############################################################################

## create trees using clustalo
    # for barcode in $( cat list.barcodes_F.txt ); do 
    #   echo $barcode
    #   /home/groups/VEO/tools/clustalo/v1.2.4/clustalo  --force -v --threads=30  \
    #   -i $wd/files/$barcode.$QC.fastq.fasta \
    #   -o $wd/files/$barcode.$QC.fastq.fasta.aligned 
    #   #--guidetree-out=$wd/files/$barcode.$QC.fastq.fasta.guidetree
    #   #--iterations 100 --output-order=tree-order --max-guidetree-iterations=100 \
    # done 
###############################################################################
## count the numbers
    # ( mkdir $wd/count ) > /dev/null 2>&1
    # for barcode in $( cat list.barcodes_F.txt ); do 
    # echo $barcode
    #   #sed 's/XYZ/'$barcode'/g' sbatch_templates/template.count_numbers_standard.sbatch > tmp/sbatch/count_numbers.$barcode.sbatch
    #   #sbatch tmp/sbatch/count_numbers.$barcode.sbatch
    # done 
###############################################################################
## chop sequences that are before and after F and R primers

    # while IFS= read -r line; do
    # echo "$line"

    #   F=$(echo $line | awk '{print $3}' )
    #   R=$(echo $line | awk '{print $4}' )
    #   sed 's/process/chopSEQ/' tmp/sbatch_templates/sbatch_template_standard.sbatch > tmp/sbatch/chopSEQ.$F.$R.sbatch
    #   echo "echo \"chopseq for $F.$R started\"" >> tmp/sbatch/chopSEQ.$F.$R.sbatch
    #   echo "source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh" >> tmp/sbatch/chopSEQ.$F.$R.sbatch
    #   echo "conda activate chopSEQ_v0.3" >> tmp/sbatch/chopSEQ.$F.$R.sbatch

    #   echo "python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/chopSEQ.py \
    #   -i data/pod5_basecalled_dorado_duplex_fastq/all_combined.subsampled_10000.fastq \
    #   -f $F -r $R -l 400 -m 700 > $wd/tmp/all_combined.subsampled_10000.$F.$R.chopped700.fasta" >> tmp/sbatch/chopSEQ.$F.$R.sbatch
        
    #   echo "echo \"chopseq for $F.$R finished\"" >> tmp/sbatch/chopSEQ.$F.$R.sbatch

    #   sbatch tmp/sbatch/chopSEQ.$F.$R.sbatch
            
    # done < list.barcodes.txt

    # for barcode in $(cat list.barcodes_R.txt ); do 
    #   F=$(grep $barcode list.barcodes.txt | awk '{print $3}' )
    #   R=$(grep $barcode list.barcodes.txt | awk '{print $4}' )
    #   sed 's/process/chopSEQ/' tmp/sbatch_templates/sbatch_template_standard.sbatch > tmp/sbatch/chopSEQ.$barcode.sbatch
    #   echo "echo \"chopseq for $barcode started\"" >> tmp/sbatch/chopSEQ.$barcode.sbatch
    #   echo "source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh" >> tmp/sbatch/chopSEQ.$barcode.sbatch
    #   echo "conda activate chopSEQ_v0.3" >> tmp/sbatch/chopSEQ.$barcode.sbatch

    #   echo "python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/chopSEQ.py \
    #   -i $wd/files/$barcode.$QC.fastq.fasta \
    #   -f $F -r $R -l 400 -m 700 > $wd/files/$barcode.$QC.fastq.chopped700.fasta" >> tmp/sbatch/chopSEQ.$barcode.sbatch
        
    #   echo "echo \"chopseq for $barcode finished\"" >> tmp/sbatch/chopSEQ.$barcode.sbatch

    #   sbatch tmp/sbatch/chopSEQ.$barcode.sbatch
    # done 
###############################################################################
## run mafft alignment
    # ( mkdir results/mafft ) > /dev/null 2>&1
    # for barcode in $(cat list.barcodes_F.txt); do 
    #   sed 's/process/mafft/g' tmp/sbatch_templates/sbatch_template_standard.sbatch > tmp/sbatch/mafft.$barcode.sbatch
    #   sed -i 's/standard/fat/g' tmp/sbatch/mafft.$barcode.sbatch
    #   echo " echo \"mafft started for $barcode\"" >> tmp/sbatch/mafft.$barcode.sbatch
    #   echo "/home/groups/VEO/tools/mafft/v7.505/bin/mafft --reorder /home/xa73pav/projects/p_nanopore_third_run_24h/$wd/files/$barcode.$QC.fastq.chopped700.fasta > /home/xa73pav/projects/p_nanopore_third_run_24h/results/mafft/$barcode.$QC.fastq.chopped700.fasta.mafft.aligned" >> tmp/sbatch/mafft.$barcode.sbatch
    #   echo " echo \"mafft finished for $barcode\"" >> tmp/sbatch/mafft.$barcode.sbatch
    #   sbatch tmp/sbatch/mafft.$barcode.sbatch
    # done 

    # for barcode in $(cat list.barcodes_R.txt); do 
    #   sed 's/process/mafft/g' tmp/sbatch_templates/sbatch_template_standard.sbatch > tmp/sbatch/mafft.$barcode.sbatch
    #   sed -i 's/standard/fat/g' tmp/sbatch/mafft.$barcode.sbatch
    #   echo " echo \"mafft started for $barcode\"" >> tmp/sbatch/mafft.$barcode.sbatch
    #   echo "/home/groups/VEO/tools/mafft/v7.505/bin/mafft --reorder /home/xa73pav/projects/p_nanopore_third_run_24h/$wd/files/$barcode.$QC.fastq.chopped700.fasta > /home/xa73pav/projects/p_nanopore_third_run_24h/results/mafft/$barcode.$QC.fastq.chopped700.fasta.mafft.aligned" >> tmp/sbatch/mafft.$barcode.sbatch
    #   echo " echo \"mafft finished for $barcode\"" >> tmp/sbatch/mafft.$barcode.sbatch
    #   sbatch tmp/sbatch/mafft.$barcode.sbatch
    # done 
###############################################################################

