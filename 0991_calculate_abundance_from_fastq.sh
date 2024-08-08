############################################################################### 
## header and preparation
    pipeline=0991_calculate_abundance_from_fastq
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	(mkdir -p $wd/tmp/list_BarcodePrimers/samples ) > /dev/null 2>&1

    create_directories_structure_1 $wd
    subsampling=no
    QC=10
    my_blast_mismatches=( 100 ) ## 10 15 100
    anticipated_read_length=$( grep my_anticipated_read_length $parameters | awk '{print $2}' )
    minlength=$(( $anticipated_read_length - 50 ))
    maxlength=$(( $anticipated_read_length + 200 ))
    rawFastqFile=$(grep my_fastq_file $parameters | awk '{print $2}')
    filteredFastqFile=$raw_files/all_combined.$QC.fastq
    # mismatches=( 0 1 2 3 4)
    # subsamples_list=( 1000000 2000000 3000000 4000000 )
	bp=$wd/tmp/list_BarcodePrimers
    threads=20
    run_id=$( pwd | awk -F'/' '{print $NF}' | awk -F'_' '{print $NF}') ## only for some analysis
 
    rm $wd/tmp/sbatch/*.* > /dev/null 2>&1
    rm $wd/tmp/slurm/*.* > /dev/null 2>&1
    
    database_parameter=$( grep my_database $parameters | awk '{print $2}' )
    if [[ $database_parameter == "silva" ]] ; then 
		database="/work/groups/VEO/databases/silva/v138.1/SILVA_138.1_SSUParc_tax_silva.2.fasta.db"
	elif [[ $database_parameter == "query_sequences" ]] ; then 
		database="$wd/databases/query_sequence.fasta.db"
	else
		echo "ERROR: database not found (database_parameter=$database_parameter)"
		exit 1
	fi

    if [[ $rawFastqFile == *.gz ]] ; then 
        if [ ! -f  $wd/all_combined.fastq ]; then 
        gunzip -c $rawFastqFile > $wd/all_combined.fastq
        fi
        rawFastqFile=$wd/all_combined.fastq
    fi 

############################################################################### 
## step-01: create barcode files 
    if [ ! -f $bp/list.barcodes_all.RC.txt ] ; then 
        ( rm $bp/list.barcodes_F.fasta ) > /dev/null 2>&1
        ( rm $bp/list.barcodes_R.fasta ) > /dev/null 2>&1
        tail -n +2 tmp/parameters/$pipeline.my_barcode.txt | while read -r line; do
            if [ -z "$line" ]; then
                continue
            fi
            id=$(echo $line | awk '{print $2}' )
            F_primer=$(echo $line | awk '{print $4}' )
            R_primer=$(echo $line | awk '{print $5}' )
            echo ">$id"_F >> $bp/list.barcodes_F.fasta
            echo "$F_primer" >> $bp/list.barcodes_F.fasta
            echo ">$id"_R >> $bp/list.barcodes_R.fasta
            echo "$R_primer" >> $bp/list.barcodes_R.fasta
        done 

        python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/reverse_complement.py \
        -i $bp/list.barcodes_F.fasta -o $bp/list.barcodes_F_RC.fasta

        python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/reverse_complement.py \
        -i $bp/list.barcodes_R.fasta -o $bp/list.barcodes_R_RC.fasta

        cat $bp/list.barcodes_F.fasta $bp/list.barcodes_R.fasta | grep -v ">" > $bp/list.barcodes_all.FR.txt
        cat $bp/list.barcodes_R_RC.fasta $bp/list.barcodes_F_RC.fasta  | grep -v ">" > $bp/list.barcodes_all.RC.txt

        #@Swapnil, work out unique barcodes, to avoid repetition in the extraction and other downstream process
        # cat list.barcodes_F.fasta list.barcodes_R.fasta | grep -v ">" | sort | uniq  > $bp/list.barcodes_all.FR.uniq.txt ## so that there should not be repetition in the extraction and other downstream process 
        # cat list.barcodes_R_RC.fasta list.barcodes_F_RC.fasta  | grep -v ">" | sort | uniq > $bp/list.barcodes_all.RC.uniq.txt ## so that there should not be repetition in the extraction and other downstream process 

        paste $bp/list.barcodes_all.FR.txt $bp/list.barcodes_all.RC.txt | sed 's/\t/\./g' > $bp/tmp.tmp
        awk 'NR>1 {print $2}' tmp/parameters/$pipeline.my_barcode.txt | sed '/^$/d' > $bp/tmp2.tmp
        awk 'NR>1 {print $2}' tmp/parameters/$pipeline.my_barcode.txt | sed '/^$/d' >> $bp/tmp2.tmp
        paste $bp/tmp.tmp $bp/tmp2.tmp > $bp/list.barcodes.names.txt 
        rm $bp/tmp.tmp 
        rm $bp/tmp2.tmp
        else
        log "ALREADY FINISHED : creating barcode files"
    fi 
 
###############################################################################
## step-02: OPTIONAL : Combine all fastqs and count of number of reads 

        # if [ ! -f results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq ] ; then 
        #     for i in $(ls results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_files/pass/ ); do
        #         echo "$i"
        #         cat results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_files/pass/*.fastq \
        #         >> results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq
        #     done
        #     else
        #     log "ALREADY FINISHED : combining all fastqs"
        # fi 
        
    ## count total number of reads 
    if [ ! -f $wd/tmp/total_number_of_reads.txt ] ; then 
        echo "calculating total number of reads"
        count_reads_from_fastq $rawFastqFile > $wd/tmp/total_number_of_reads.txt
        else
        log "ALREADY FINISHED : total number of reads"
    fi 

    total_number_of_reads=$(cat $wd/tmp/total_number_of_reads.txt)
    echo "total_number_of_reads : $total_number_of_reads"
 
###############################################################################
## step-03: filter reads (by chopper) for $QC

    if [ ! -f $raw_files/all_combined.$QC.fastq ] ; then 
        log "STARTED : filtering reads (by chopper) for QC $QC"
        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 

        cat $rawFastqFile \
        | chopper -t $threads --minlength $minlength --maxlength $maxlength -q $QC \
        > $raw_files/all_combined.$QC.fastq

        log "FINISHED : filtering reads (by chopper) for QC $QC"
        else
        log "ALREADY FINISHED : filtering reads (by chopper) for QC $QC"
    fi

    if [ ! -f $wd/tmp/total_number_of_filtered_reads.$QC.txt ] ; then 
        log "counting total number of filtered reads"
        count_reads_from_fastq $filteredFastqFile > $wd/tmp/total_number_of_filtered_reads.$QC.txt
    fi

    filtered_reads=$(cat $wd/tmp/total_number_of_filtered_reads.$QC.txt)
    echo "filtered_reads : $filtered_reads"  

############################################################################### 
## step-04: subsampling

    if [ ! -d $wd/subsampled ] ; then 
        (mkdir -p $wd/subsampled ) > /dev/null 2>&1

        if [ "$subsampling" == "no" ] ; then 

            subsample=$filtered_reads
            cp $filteredFastqFile $wd/subsampled/all_combined.subsampled_"$subsample".fastq
            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk seq -a $filteredFastqFile > $filteredFastqFile.fasta
            
            elif [ "$subsampling" == "yes" ] ; then 
            subsamples=${subsamples_list[@]}

                source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 
                for subsample in "${subsamples[@]}"; do
                    if [ ! -f $wd/subsampled/all_combined.subsampled_"$subsample".fastq ] ; then 
                        log "subsampling for $subsample"
                        rasusa -i $rawFastqFile \
                        -n $subsample -o $wd/subsampled/all_combined.subsampled_"$subsample".fastq -O u
                    fi
                done
        fi

        else
        log "ALREADY FINISHED : subsampling"
    fi

    ## needed for below script
    if [ "$subsampling" == "no" ] ; then 
        subsamples=$filtered_reads
        elif [ "$subsampling" == "yes" ] ; then
        subsamples=${subsamples_list[@]}
        else
        echo "provide subsamples option"
    fi 

###############################################################################
## step-05: extract_read-ids_from_fastq_if_pattern_present
    ## file written is $wd/lists/list.$barcode.read_ids.$subsample.txt
    ## file written is $wd/lists/list.$barcode.read_ids.only.$subsample.txt

    if [ ! -d $raw_files/read_ids_extracted ] ; then 
        mkdir -p $raw_files/read_ids_extracted > /dev/null 2>&1

        for subsample in "${subsamples[@]}"; do

            for barcode_FR in $(cat $bp/list.barcodes_all.FR.txt); do 
                if [ ! -f $raw_files/read_ids_extracted/list.$barcode_FR.read_ids.only.$subsample.txt ] ; then 
                    log "creating and submitting sbatch for $barcode_FR $barcode_FR"
                    sed "s/ABC/$barcode_FR/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_extract_read_ids.sbatch | sed "s/XYZ/$subsample/g" \
                    > $wd/tmp/sbatch/extract_read_ids.$barcode_FR.$subsample.sbatch
                    sbatch $wd/tmp/sbatch/extract_read_ids.$barcode_FR.$subsample.sbatch
                    wait_for_jobs_to_complete 50
                fi
            done
            
            for barcode_RC in $(cat $bp/list.barcodes_all.RC.txt); do 
                if [ ! -f $raw_files/read_ids_extracted/list.$barcode_RC.read_ids.only.$subsample.txt ] ; then 
                    log "creating and submitting sbatch for $barcode_RC $barcode_RC"
                    sed "s/ABC/$barcode_RC/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_extract_read_ids.sbatch | sed "s/XYZ/$subsample/g" \
                    > $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch
                    sbatch $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch
                    wait_for_jobs_to_complete 50
                fi
            done

        done 

        else
        log "ALREADY FINISHED : extract_read-ids_from_fastq_if_pattern_present"
    fi

    wait_till_all_job_finished 01_0991
    # first checkpoint for sbatch 
    # exit 
###############################################################################
## step-06: combine read ids from F, R and RC sequences, remove duplicates, also make a count

    for subsample in "${subsamples[@]}"; do
        if [ ! -f $wd/tmp/number_of_reads.read_ids.$subsample.tsv ] ; then 

            log "RUNNING: $subsample combining read ids, removing duplicates and counting "
            while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do
                num_of_barcode_FR=$( wc -l $raw_files/read_ids_extracted/list.$barcode_FR.read_ids.$subsample.txt | awk '{print $1}' )
                num_of_barcode_RC=$( wc -l $raw_files/read_ids_extracted/list.$barcode_RC.read_ids.$subsample.txt | awk '{print $1}' )
                num_of_new_reads_by_RC=$(diff \
                $raw_files/read_ids_extracted/list.$barcode_FR.read_ids.$subsample.txt \
                $raw_files/read_ids_extracted/list.$barcode_RC.read_ids.$subsample.txt \
                | grep "^>" | sed 's/^> //' | wc -l )

                cat $raw_files/read_ids_extracted/list.$barcode_FR.read_ids.$subsample.txt \
                $raw_files/read_ids_extracted/list.$barcode_RC.read_ids.$subsample.txt | \
                sort | uniq | sed 's/\@//g'> $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt

                non_duplicate_read_ids=$(($num_of_barcode_FR + $num_of_new_reads_by_RC ))

                echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids
                echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids \
                > $raw_files/read_ids_extracted/number_of_reads.$barcode_FR.$barcode_RC.read_ids.$subsample.txt

                echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids \
                >> $wd/tmp/number_of_reads.read_ids.$subsample.tsv
            done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"

            else
            log "ALREADY FINISHED : $subsample combining read ids, removing duplicates and counting"
        fi 
    done

############################################################################### 
## step-07: get seperate fastqs for barcode/match
    ## out file is  $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$subsample.fastq"

    if [ ! -d $raw_files/read_ids_extracted_fastq ] ; then
        ( mkdir $raw_files/read_ids_extracted_fastq ) > /dev/null 2>&1

        for subsample in "${subsamples[@]}"; do
            while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do
                if [ ! -f  $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$subsample.fastq ] ; then 
                    log "step-07: get seperate fastqs for barcode/match for $barcode_FR $barcode_RC $subsample"
                    sed "s/ABC/$barcode_FR/g" $suppl_scripts/0991_calculate_abundance_from_fastq.get_reads_by_seqtk.sbatch \
                    | sed "s/DEF/$barcode_RC/g" | sed "s/JKL/$subsample/g" | sed "s/my_QC_value/$QC/g" \
                    > $wd/tmp/sbatch/0991_calculate_abundance_from_fastq.get_reads_by_seqtk.$barcode.$barcode_RC.$subsample.sbatch
                    sbatch $wd/tmp/sbatch/0991_calculate_abundance_from_fastq.get_reads_by_seqtk.$barcode.$barcode_RC.$subsample.sbatch
                    
                    wait_for_jobs_to_complete 50
                fi 
            done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"

        done 

        else
        log "ALREADY FINISHED : get seperate fastqs for barcode_FR and barcode_RC"
    fi

    wait_till_all_job_finished 02_0991
    ## second checkpoint for sbatch stop
    # exit 

    ## just for QC (run only when above loop is completely finished)
    if [ ! -f $wd/tmp/percentage_reads_binned.$subsample.txt ] ; then 
        number_of_reads=0
        for subsample in "${subsamples[@]}"; do
            while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do
                lines_in_file=$(wc -l  $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$QC.$subsample.fastq | awk '{print $1}')
                reads_in_file=$(( $lines_in_file / 4 ))
                # echo $barcode.$barcode_RC.$subsample : $reads_in_file
                total_number_of_reads=$(( $number_of_reads + $reads_in_file ))
                number_of_reads=$total_number_of_reads
            done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
        done 
        percentage_reads_got_binned=$(( $number_of_reads * 100 / $subsample ))
        echo "$percentage_reads_got_binned percentage ($number_of_reads/$subsample) of reads binned" \
        > $wd/tmp/percentage_reads_binned.$subsample.txt
    fi
    percentage_reads_binned=$(cat $wd/tmp/percentage_reads_binned.$subsample.txt )
    log "percentage_reads_binned : $percentage_reads_binned"
 
###############################################################################
## step-08: fastq2fasta for filtered reads  
    ## for better subsequent processing, need to convert fastq to fasta
    if [ ! -f $wd/tmp/total_number_of_reads_in_FR_RC_fasta.txt ] ; then 
        for subsample in "${subsamples[@]}"; do
            while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do 
                if [ ! -f  $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta ] ; then 
                    echo "$barcode_FR && $barcode_RC for $subsample"
                    python3 $suppl_scripts/0991_fastq2fasta.py \
                    -i  $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.$subsample.fastq \
                    -o  $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta

                    lines_in_fasta10=$(wc -l  $raw_files/read_ids_extracted_fastq/$barcode_FR.$barcode_RC.$QC.fastq.$subsample.fasta | awk '{print $1}')
                    reads_in_fasta10=$(( $lines_in_fasta10 / 2 ))
                    echo "$barcode_FR $barcode_RC $reads_in_fasta10" | tee -a $wd/tmp/total_number_of_reads_in_FR_RC_fasta.txt
                fi 
            done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
        done
        log "ALREADY FINISHED : fastq2fasta for filtered reads"
    fi
 
###############################################################################
## step-09: QC: count the number of reads  
    if [ ! -f $wd/tmp/total_number_of_reads.$QC.txt ] ; then 
        for subsample in "${subsamples[@]}"; do
            while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 

                number_of_reads_ids_in_FR=$( wc -l $raw_files/read_ids_extracted/list.$barcode.read_ids.$subsample.txt | awk '{print $1}' )
                number_of_reads_ids_in_RC=$( wc -l $raw_files/read_ids_extracted/list.$barcode_RC.read_ids.$subsample.txt | awk '{print $1}' )
                number_of_total_read_ids=$(( $number_of_reads_ids_in_FR + $number_of_reads_ids_in_RC )) ## here duplicates are not removed

                lines=$(wc -l  $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$QC.$subsample.fastq | awk '{print $1}' )
                non_duplicate_reads=$(( $lines / 4 ))

                lines_10=$(wc -l  $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$QC.$subsample.fastq | awk '{print $1}')
                reads_10=$(( $lines_10 / 4 ))

                lines_in_fasta10=$(wc -l  $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$QC.fastq.$subsample.fasta | awk '{print $1}')
                reads_in_fasta10=$(( $lines_in_fasta10 / 2 ))

                echo "$barcode && $barcode_RC : $number_of_total_read_ids $non_duplicate_reads $reads_10 $reads_in_fasta10" 
                echo "$barcode && $barcode_RC : $number_of_total_read_ids $non_duplicate_reads $reads_10 $reads_in_fasta10" >> $wd/tmp/total_number_of_reads.$QC.txt

            done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
        done
    fi
    log "FINISHED : QC: count the number of reads"

###############################################################################
## step-10a: run blast  

    if [[ $database_parameter == "query_sequences" ]] ; then
        if [ ! -d $wd/databases ] ; then
            ( mkdir -p $wd/databases )
            ## reformat multi-line fasta to one line fasta
            if [ ! -f tmp/parameters/$pipeline.query_sequence.2.fasta ] ; then
                awk 'BEGIN {RS=">"; FS="\n"} NR>1 {printf ">%s\n", $1; for (i=2; i<=NF; i++) printf "%s", $i; print ""}' tmp/parameters/$pipeline.query_sequence.fasta \
                > tmp/parameters/$pipeline.query_sequence.2.fasta
            fi

            # create database for query sequence
            if [ ! -f $wd/databases/query_sequence.fasta.db.ndb ] ; then 
                /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
                -in tmp/parameters/$pipeline.query_sequence.2.fasta \
                -dbtype nucl -out $wd/databases/query_sequence.fasta.db
            fi 
        fi

        if [ ! -d $raw_files/blast_results ] ; then
            ( mkdir -p $raw_files/blast_results )
            for subsample in "${subsamples[@]}"; do
                echo "subsample: $subsample"
                ##  blast each read against each query seqeunce 
                    while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do 
                        rm $raw_files/blast_results/$barcode_FR.$barcode_RC.$QC.fastq.fasta.$subsample.tsv > /dev/null 2>&1
                        if [ ! -f $raw_files/blast_results/$barcode_FR.$barcode_RC.$QC.fastq.fasta.$subsample.tsv ] ; then 
                            sed "s/ABC/$barcode_FR/g" $suppl_scripts/0991_blast.sbatch \
                            | sed "s/JKL/$barcode_RC/g" | sed "s/XYZ/$subsample/g" | sed "s/DEF/$QC/g" \
                            > $wd/tmp/sbatch/blast.$barcode_FR.$barcode_RC.$subsample.sbatch
                            sbatch $wd/tmp/sbatch/blast.$barcode_FR.$barcode_RC.$subsample.sbatch
                        fi 
                    done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
                    
            done 
        fi
        log "FINISHED : run blast"

        wait_till_all_job_finished 03_0991
        # third check point 
        # exit 

        ## QC check for BLAST files 
            ## just check if blast files are not empty (and does not relate it to the count)
            if [ ! -f $wd/tmp/blast.QC.tsv ] ; then 
                for subsample in "${subsamples[@]}"; do
                    while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do  
                        number_of_lines=$(wc -l $raw_files/blast_results/$barcode_FR.$barcode_RC.$QC.fastq.fasta.$subsample.tsv | awk '{print $1}' )
                        echo $subsample $barcode_FR.$barcode_FR $number_of_lines
                        echo $subsample $barcode_FR.$barcode_RC $number_of_lines >> $wd/tmp/blast.QC.tsv
                    done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
                done
            fi

    fi


###############################################################################
## step-10b: run kraken2

    if [[ $database_parameter == "silva" ]] ; then
        if [ ! -d $raw_files/kraken2 ] ; then
            mkdir -p $raw_files/kraken2/hits
            for subsample in "${subsamples[@]}"; do
                while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do  
                    echo "$barcode_FR $barcode_FR barcode_RC $barcode_RC"
                    sample_id_tmp=$(grep $barcode_FR.$barcode_RC $wd/tmp/list_BarcodePrimers/list.barcodes.names.txt | awk '{print $2}')
                    sample_id=$(grep -w $sample_id_tmp tmp/parameters/0991_calculate_abundance_from_fastq.my_barcode.txt | awk '{print $1}' )
                    echo "sample_id $sample_id"
                    if [ ! -f $raw_files/kraken2/hits/$sample_id.$QC.fastq.$subsample.fasta.out ] ; then 
                        # log "submitting kraken2 sbatch for $subsample $barcode_FR $barcode_RC" 

                        sed "s/my_barcode_FR/$barcode_FR/g" $suppl_scripts/$pipeline.kraken2.sbatch \
                        | sed "s/my_barcode_RC/$barcode_RC/g" | sed "s/my_subsample/$subsample/g" | sed "s/my_QC_value/$QC/g" \
                        > $wd/tmp/sbatch/$barcode_FR.$barcode_RC.$subsample.kraken2.sbatch
                        sbatch $wd/tmp/sbatch/$barcode_FR.$barcode_RC.$subsample.kraken2.sbatch
                        wait_for_jobs_to_complete 50

                    fi 
                done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
            done 
        fi
        wait_till_all_job_finished 03_0991
        exit 
    fi 

    # exit 
############################################################################### 
## step-11: count the numbers
    ## takes long (~OVERNIGHT) time 
    if [ ! -d  $raw_files/count  ] ; then 
        ( mkdir $raw_files/count ) > /dev/null 2>&1

        for subsample in "${subsamples[@]}"; do
            for my_blast_mismatch in "${my_blast_mismatches[@]}"; do
                while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do 
                if [ ! -f $raw_files/count/$barcode_FR.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.max_"$my_blast_mismatch".tsv ] ; then 
                    log "creating and submitting sbatch for $subsample $my_blast_mismatch $barcode_FR $barcode_RC"
                    sed "s/barcode_RC/$barcode_RC/g" $suppl_scripts/0991_count_numbers.sbatch \
                    | sed "s/barcode_FR/$barcode_FR/g" | sed "s/subsample/$subsample/g" | sed "s/QC/$QC/g" | sed "s/my_blast_mismatch/$my_blast_mismatch/g" \
                    > $wd/tmp/sbatch/count_numbers.$barcode_FR.$barcode_RC.$subsample.$my_blast_mismatch.sbatch
                    sbatch $wd/tmp/sbatch/count_numbers.$barcode_FR.$barcode_RC.$subsample.$my_blast_mismatch.sbatch
                    wait_for_jobs_to_complete 50 ## can handel max ~25 on interactive node with 24 CPUs
                    else
                    log "ALREADY FINISHED : $subsample $my_blast_mismatch $barcode_FR $barcode_RC"
                fi
                done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt" 
            done
        done 

    wait_till_all_job_finished 04_0991
    ## fourth stop for sbatch
    # exit 

    for subsample in "${subsamples[@]}"; do
        for my_blast_mismatch in "${my_blast_mismatches[@]}"; do
            if [ ! -f $wd/tmp/total_hits.$QC.$subsample.tsv ] ; then
                while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do  
                    total_hits=$(awk -F'\t' '{ sum += $2 } END { print sum }' $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.max_$my_blast_mismatch.tsv )
                    echo $barcode $barcode_RC $total_hits | tee -a $wd/tmp/total_hits.$QC.$subsample.max_$my_blast_mismatch.tsv
                done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
            fi
        done 
    done

    fi
###############################################################################
## summarise the count
    grep ">" tmp/parameters/$pipeline.query_sequence.2.fasta | sed 's/>//g' | sort -u | sed 's/ .*//g' > query.fasta.list

    for subsample in "${subsamples[@]}"; do
        for my_blast_mismatch in "${my_blast_mismatches[@]}"; do
            if [ ! -f $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv  ] ; then 
                ( mkdir $wd/final_tables ) > /dev/null 2>&1 
                if [ ! -f $wd/final_tables/final_count.$subsample.max_"$my_blast_mismatch".tsv ] ; then 
                    ( rm $raw_files/count/*.$QC.fastq.fasta.2.$subsample.txt ) > /dev/null 2>&1 
                    while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 
                        echo $barcode.$barcode_RC >  $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.max_"$my_blast_mismatch".txt
                        for id in $(cat query.fasta.list ) ; do 
                            V1=$(grep -w "$id" $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.max_"$my_blast_mismatch".tsv | awk '{print $2}' )
                            if [ ! -z $V1 ]; then
                                echo $V1 >>  $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.max_"$my_blast_mismatch".txt
                                else
                                echo 0 >>  $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.max_"$my_blast_mismatch".txt
                            fi 
                        done
                    done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt" 

                    sed '1i\ids' query.fasta.list > query.fasta.list.tmp
                    paste query.fasta.list.tmp $raw_files/count/*.$QC.fastq.fasta.2.$subsample.max_"$my_blast_mismatch".txt \
                    > $wd/final_tables/final_count.$subsample.max_"$my_blast_mismatch".tsv
                    rm query.fasta.list.tmp 
                fi 

            ## QC check for number of blast_total_hits in best_hits and number of lines in count 
                if [ ! -f $wd/tmp/blast.QC.max_"$my_blast_mismatch".tmp ] ;then 
                    echo -e "subsample\tbarcode.barcode_RC\tblast_total_hits\tblast_specific_hits\tsample_hits" > $wd/tmp/blast.QC.max_"$my_blast_mismatch".tmp
                    for subsample in "${subsamples[@]}"; do
                        while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do  
                            blast_total_hits=$(wc -l $raw_files/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.$subsample.tsv | awk '{print $1}' )
                            blast_specific_hits=$(tail -n +2  $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.max_"$my_blast_mismatch".txt | awk '{sum+=$1} END {print sum}' ) 
                            sample_hits=$(wc -l $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.max_"$my_blast_mismatch".tsv | awk '{print $1}' )
                            # echo brady $subsample $barcode.$barcode_RC $blast_total_hits $sample_hits
                            echo $subsample $barcode.$barcode_RC $blast_total_hits $blast_specific_hits $sample_hits >> $wd/tmp/blast.QC.max_"$my_blast_mismatch".tmp
                        done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt"
                    done 
                fi

            # barcodes2samples renaming
            while IFS= read -r line; do
                barcode=$(echo "$line" | awk '{print $1}')
                name=$(echo "$line" | awk '{print $2}')
                sed -i "s/$barcode/$name/g" $wd/final_tables/final_count.$subsample.max_"$my_blast_mismatch".tsv
                # sed -i "s/$barcode/$name/g" $wd/final_tables/final_count.rhizo.$subsample.tsv
            done < $bp/list.barcodes.names.txt
        fi

        if [ ! -f $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv ] ; then
            (rm $wd/final_tables/all.$subsample.tsv) > /dev/null 2>&1 
            ## create final table for Brady
            for header in $(head -1 $wd/final_tables/final_count.$subsample.max_"$my_blast_mismatch".tsv | sed 's/ids//g' | tr '\t' '\n' | sed '/^$/d' |  sort -u | sort -V ) ; do 
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
                }' $wd/final_tables/final_count.$subsample.max_"$my_blast_mismatch".tsv > $wd/final_tables/$header.max_"$my_blast_mismatch".tsv

                touch $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv
                paste $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv $wd/final_tables/$header.max_"$my_blast_mismatch".tsv > $wd/final_tables/all.tmp
                mv $wd/final_tables/all.tmp $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv
                rm $wd/final_tables/$header.max_"$my_blast_mismatch".tsv 
            done 

            sed '1i\ids' query.fasta.list > query.fasta.list.tmp
            paste query.fasta.list.tmp $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv > $wd/final_tables/all.2.tsv
            sed 's/\t\t/\t/g' $wd/final_tables/all.2.tsv > $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv 
            rm query.fasta.list.tmp
            rm $wd/final_tables/all.2.tsv
        fi

        done
    done

###############################################################################
## create figure
    source /home/groups/VEO/tools/python/pandas/bin/activate

    for subsample in "${subsamples[@]}"; do
        for my_blast_mismatch in "${my_blast_mismatches[@]}"; do
            echo "creating figure for $subsample for brady"
            ## first convert the table to percentage
            python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_table_to_percetage.py \
            -i $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".tsv \
            -o $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".perc.tsv
            ## create actual figure
            python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/stacked_column_chart.py \
            -i $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".perc.tsv \
            -o $wd/final_tables/all.$subsample.max_"$my_blast_mismatch".perc.tsv.png
        done
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
    #   -i  $raw_files/read_ids_extracted_fastq/$barcode.$QC.fastq.fasta \
    #   -o  $raw_files/read_ids_extracted_fastq/$barcode.$QC.fastq.fasta.aligned 
    #   #--guidetree-out= $raw_files/read_ids_extracted_fastq/$barcode.$QC.fastq.fasta.guidetree
    #   #--iterations 100 --output-order=tree-order --max-guidetree-iterations=100 \
    # done 
###############################################################################
## count the numbers
    # ( mkdir $raw_files/count ) > /dev/null 2>&1
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
    #   -i  $raw_files/read_ids_extracted_fastq/$barcode.$QC.fastq.fasta \
    #   -f $F -r $R -l 400 -m 700 >  $raw_files/read_ids_extracted_fastq/$barcode.$QC.fastq.chopped700.fasta" >> tmp/sbatch/chopSEQ.$barcode.sbatch
        
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
    #   echo "/home/groups/VEO/tools/mafft/v7.505/bin/mafft --reorder /home/xa73pav/projects/p_nanopore_third_run_24h/ $raw_files/read_ids_extracted_fastq/$barcode.$QC.fastq.chopped700.fasta > /home/xa73pav/projects/p_nanopore_third_run_24h/results/mafft/$barcode.$QC.fastq.chopped700.fasta.mafft.aligned" >> tmp/sbatch/mafft.$barcode.sbatch
    #   echo " echo \"mafft finished for $barcode\"" >> tmp/sbatch/mafft.$barcode.sbatch
    #   sbatch tmp/sbatch/mafft.$barcode.sbatch
    # done 

    # for barcode in $(cat list.barcodes_R.txt); do 
    #   sed 's/process/mafft/g' tmp/sbatch_templates/sbatch_template_standard.sbatch > tmp/sbatch/mafft.$barcode.sbatch
    #   sed -i 's/standard/fat/g' tmp/sbatch/mafft.$barcode.sbatch
    #   echo " echo \"mafft started for $barcode\"" >> tmp/sbatch/mafft.$barcode.sbatch
    #   echo "/home/groups/VEO/tools/mafft/v7.505/bin/mafft --reorder /home/xa73pav/projects/p_nanopore_third_run_24h/ $raw_files/read_ids_extracted_fastq/$barcode.$QC.fastq.chopped700.fasta > /home/xa73pav/projects/p_nanopore_third_run_24h/results/mafft/$barcode.$QC.fastq.chopped700.fasta.mafft.aligned" >> tmp/sbatch/mafft.$barcode.sbatch
    #   echo " echo \"mafft finished for $barcode\"" >> tmp/sbatch/mafft.$barcode.sbatch
    #   sbatch tmp/sbatch/mafft.$barcode.sbatch
    # done 
###############################################################################

