#!/bin/bash
###############################################################################
## header
    pipeline=0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline -------------------"
###############################################################################
## step-00: preparation
    guppy_basecaller=/home/groups/VEO/tools/ont-guppy/v6.5.7_gpu/bin/guppy_basecaller
    pod5_file_path=$(grep pod5 tmp/parameters/files_in_data_directory.txt | awk '{print $NF}')
    parameter_file_data=$(grep -Ev '^\s*#|^\s*$' tmp/parameters/$pipeline.txt | wc -l)

    ls $pod5_file_path | sed 's/\.pod5//g' > list.pod5.txt
    list=list.pod5.txt
    
    create_directories_structure_1 $wd
    split_list $wd $list

############################################################################### 
## step-01: converting pod5 to fast5 
    ## input: $pod5_file_path/$i
    ## output: $wd/01_pod5_fast5

        ( rm $wd/tmp/slurm/*.out.01_pod5_fast5 ) > /dev/null 2>&1    ## old slurm files may cause confusion for checking the status
        ( rm $wd/tmp/slurm/*.err.01_pod5_fast5 ) > /dev/null 2>&1    ## old slurm files may cause confusion for checking the status

    if [ ! -d $raw_files/01_pod5_fast5 ] ; then 
        ( mkdir -p $raw_files/01_pod5_fast5 ) > /dev/null 2>&1 
        
        for sublist in $( ls $wd/tmp/lists/ ) ; do
            sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.01_pod5_to_fast5.sbatch \
            > $wd/tmp/sbatch/$pipeline.pod5_to_fast5.$sublist.sbatch
            
            sbatch $wd/tmp/sbatch/$pipeline.pod5_to_fast5.$sublist.sbatch > /dev/null 2>&1
            log "SBATCH SUBMITTED : $pipeline.pod5_to_fast5 : $sublist"
        done


        log "CHECKING : the status for step-01: converting pod5 to fast5 (will take 1 min)"
        sleep 60
        number_of_files=$( ls $pod5_file_path | wc -l )
        number_of_files_finished=$(grep "Conversion complete" $wd/tmp/slurm/*.out.01_pod5_fast5 | wc -l )
        while [ "$number_of_files" -ne "$number_of_files_finished" ]; do
            number_of_files_finished=$(grep "Conversion complete" $wd/tmp/slurm/*.out.01_pod5_fast5 | wc -l )
            number_of_files_remained=$(( $number_of_files - $number_of_files_finished ))
            log "$number_of_files_finished/$number_of_files finished, still $number_of_files_remained to be processed, ... waiting for 3 min"
        sleep 60
        done

        log "FINISHED : step-01 : converting pod5 to fast5 ----------------------------------"
        else 
        log "ALREADY FINISHED : step-01 : converting pod5 to fast5 --------------------------"

    fi

############################################################################### 
## step-02: 02_fast5_to_basecall : $raw_files/02_fast5_to_basecall/all_files/$i.fast5/pass

    log "STARTED : 02_fast5_to_basecall -------------------------------------------"
    if [ ! -d $raw_files/02_fast5_to_basecall ] ; then
        ( rm $wd/tmp/slurm/*.out.02_fast5_to_basecall ) > /dev/null 2>&1    ## old slurm files may cause confusion for checking the status
        ( rm $wd/tmp/slurm/*.err.02_fast5_to_basecall ) > /dev/null 2>&1    ## old slurm files may cause confusion for checking the status

        sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.02_fast5_to_basecall.sbatch > /dev/null 2>&1 

        log " CHECKING : the status for step-02: basecalling (will take 1 min)"
        sleep 60 
        number_of_files=$( ls $pod5_file_path | wc -l )
        number_of_files_finished=$(grep "basecalling finished" $wd/tmp/slurm/*.out.02_fast5_to_basecall | wc -l )
        while [ "$number_of_files" -ne "$number_of_files_finished" ]; do
            number_of_files_finished=$(grep "basecalling finished" $wd/tmp/slurm/*.out.02_fast5_to_basecall | wc -l )
            number_of_files_remained=$(( $number_of_files - $number_of_files_finished ))
            log "$number_of_files_finished/$number_of_files finished for basecalling, still $number_of_files_remained to be processed, ... waiting for 3 min"
        sleep 60
        done

        else
        log "ALREADY FINISHED : step-02 : basecalling step ----------------------------------"
    fi

    # simply combine all fastqs to one fastq 
    # step-needed for the abundance study
    if [ ! -f $raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq ] ; then 
        ( mkdir -p $raw_files/02_fast5_to_basecall/all_fastqs  ) > /dev/null 2>&1 
        for i in $(ls $raw_files/02_fast5_to_basecall/all_files/pass/ ); do
            log "COMBINING : step-02 : fastq $i to all_combined.fastq"
            cat $raw_files/02_fast5_to_basecall/all_files/pass/$i \
            >> $raw_files/02_fast5_to_basecall/all_fastqs/all_combined.fastq
        done
        else 
        log "ALREADY FINISHED : step-02 : combining step "
    fi
    log "FINISHED : 02_fast5_to_basecall -------------------------------------------"
exit 
###############################################################################
## step-03: demultiplexing : demultiplexed_files
    if [ $parameter_file_data -ne 0 ] ; then 
        if [ ! -d $raw_files/03_basecall_to_demultiplex ] ; then
            log "STARTED : step-03: demultiplexing step -------------------------------------------"
            ( mkdir $raw_files/03_basecall_to_demultiplex  ) > /dev/null 2>&1 
            ( rm $wd/tmp/slurm/*.out.03_basecall_to_demultiplex ) > /dev/null 2>&1
            ( rm $wd/tmp/slurm/*.err.03_basecall_to_demultiplex ) > /dev/null 2>&1

            ## if you want to run the demultiplexing in parallel
            # for sublist in $( ls $wd/tmp/lists/ ) ; do
            #     sed "s/ABC/$sublist/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.03_basecall_to_demultiplex.sbatch | sed "s|XYZ|$wd|g" > $wd/tmp/sbatch/$sublist.sbatch
            #     ( sbatch $wd/tmp/sbatch/$sublist.sbatch ) > /dev/null 2>&1 
            #     log "SUBMITTED : step-03 : sbatch for demultiplexing $sublist"
            # done 

            ## if you want to run the demultiplexing in serial
            for sublist in $( ls $wd/tmp/lists/ ) ; do
                sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.03_basecall_to_demultiplex.sbatch 
                log "SUBMITTED : step-03 : sbatch for demultiplexing $sublist"
            done 


            log "CHECKING : the status for step-03: demultiplexing (will take 1 min)"
            sleep 60 
            number_of_files_finished=0
            while [ "$number_of_files" -ne "$number_of_files_finished" ]; do
                number_of_files_finished=$(grep "demultiplexing finished" $wd/tmp/slurm/*.out.03_basecall_to_demultiplex | wc -l )
                number_of_files_remained=$(( $number_of_files - $number_of_files_finished ))
                log "$number_of_files_finished/$number_of_files finished for demultiplexing, still $number_of_files_remained to be processed, ... waiting for 3 min"
                sleep 60
            done
            log "step-03: demultiplexing finished -----------------------------------------------"
            else
            log "step-03: demultiplexing step already finished ----------------------------------"
        fi
    fi 
    exit 
###############################################################################
## step-04: collect data coming from different files to single file ## $raw_files/04_demultiplex_to_combinedBarcodeFastq
    if [ $parameter_file_data -ne 0 ] ; then 
    log "step-04: fastq combining step: running: ---------------------------------------------"

    if [ ! -d $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw ] ; then 
        (mkdir -p $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw ) > /dev/null 2>&1 
        (mkdir -p $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10 ) > /dev/null 2>&1 
        ## get the list of identified barcodes
            find $raw_files/03_basecall_to_demultiplex/ -type d -name "barcode*" \
            | awk -F'/' '{print $NF}' | sort | uniq \
            > $wd/tmp/lists/list.barcodes.txt
            echo "unclassified" >> $wd/tmp/lists/list.barcodes.txt

        ## working bash loop, demoted for slower speed
            for barcode in $(cat $wd/tmp/lists/list.barcodes.txt ) ; do 
                log "STARTED : $pipeline : $barcode : combining fastq files"
                ( cat $raw_files/03_basecall_to_demultiplex/$barcode/*.fastq \
                >> $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw/$barcode.fastq ) > /dev/null 2>&1 
            done


                ## above bash loop can be faster in python as (so promoted)
                ## @Swapnil20231201, howerever below python script did not work
                    # /home/groups/VEO/tools/python/v3.7.12/bin/python3.7 $wd/tmp/sbatch//0008_step04_concatenate_fastq_barcodes.py

        ## filter QC>10 reads (by chopper)
            source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 
            for barcode in $( cat $wd/tmp/lists/list.barcodes.txt ); do 
                log "STARTED : fastqs QC>10 filtering for $barcode"
                cat $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw/$barcode.fastq | chopper -q 10 \
                > $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10/$barcode.10.fastq
            done 
            
            cat $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw/*.fastq > $raw_files/raw_files.fastq
            cat $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10/*.10.fastq > $raw_files/raw_files.10.fastq


        ## create stat file 
            ( rm $raw_files/04_demultiplex_to_combinedBarcodeFastq/stat.txt ) > /dev/null 2>&1 
            for barcode in $(cat $wd/tmp/lists/list.barcodes.txt) ; do 
                read_count=$( cat $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw/$barcode.fastq | echo $((`wc -l`/4)) )
                read_count_10=$( cat $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10/$barcode.10.fastq | echo $((`wc -l`/4)) )
                echo $barcode $read_count >> $wd/stat.fastq.tsv
                echo $barcode $read_count_10 >> $wd/stat.fastq10.tsv
            done

        ## gzip
            for barcode in $(cat $wd/tmp/lists/list.barcodes.txt) ; do 
                mkdir -p $raw_files/04_demultiplex_to_combinedBarcodeFastq/raw_gzip > /dev/null 2>&1
                mkdir -p $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10_gzip > /dev/null 2>&1
                sed "s/my_barcode/$barcode/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.04_fastq_to_gzip.sbatch \
                > $wd/tmp/sbatch/"$barcode"_compressing.sbatch
                ( sbatch $wd/tmp/sbatch/"$barcode"_compressing.sbatch ) > /dev/null 2>&1
                log "SUBMITTED : sbatch for Compressing $barcode"
            done

        else
        log "step-04: fastq combining step: already finished ---------------------------------"
    fi 

    log "step-04: fastq combining step: finished --------------------------------------------"
    fi
###############################################################################
## step-05: renaming
    if [ $parameter_file_data -ne 0 ] ; then 
    if  [ ! -d data/fastq ] ; then 
        if [ -f tmp/parameters/$pipeline.txt ] ; then 
            log "renaming files"
            grep -v "#" tmp/parameters/$pipeline.txt | awk '{print $1}' > tmp/parameters/$pipeline.barcode.txt
            grep -v "#" tmp/parameters/$pipeline.txt | awk '{print $2}' > tmp/parameters/$pipeline.samples.txt

            ( mkdir -p data/fastq ) > /dev/null 2>&1
            exec 3<tmp/parameters/$pipeline.barcode.txt
            exec 4<tmp/parameters/$pipeline.samples.txt
            while read barcode <&3; read ids <&4 ; do 
                echo "$barcode.10.fastq.gz renamed as $ids.10.fastq.gz"
                cp $raw_files/04_demultiplex_to_combinedBarcodeFastq/QC10_gzip/$barcode.10.fastq.gz data/fastq/$ids.10.fastq.gz
            done

            rm tmp/parameters/$pipeline.barcode.txt
            rm tmp/parameters/$pipeline.samples.txt
            else
            log "tmp/parameters/$pipeline.barcode.txt and tmp/parameters/$pipeline.barcode_corresponding_ids.txt not found, skipping"
        fi
        else
        log "data/fastq already exists"
    fi
    fi
###############################################################################
## step-06:  get QC for all the reads
    if [ ! -f $wd/summary.tsv ]; then 
        log "RUNNING : STEP-06 : creating stat file"
        echo -e "TRUE\tFALSE" > $raw_files/02_fast5_to_basecall/stat.reads_pass_sequencing_summary.tsv
        true=$(grep -c -w "TRUE" $raw_files/02_fast5_to_basecall/sequencing_summary.txt)
        false=$(grep -c -w "FALSE" $raw_files/02_fast5_to_basecall/sequencing_summary.txt)
        echo -e "$true\t$false" >> $raw_files/02_fast5_to_basecall/stat.reads_pass_sequencing_summary.tsv
        reads_after_basecalling_passed=$(awk 'NR>1 { sum += $1 } END { print sum }' $raw_files/02_fast5_to_basecall/stat.reads_pass_sequencing_summary.tsv) #true
        reads_after_basecalling_failed=$(awk 'NR>1 { sum += $2 } END { print sum }' $raw_files/02_fast5_to_basecall/stat.reads_pass_sequencing_summary.tsv) #false
        reads_after_basecalling=$(( $reads_after_basecalling_passed + $reads_after_basecalling_failed ))

        echo -e "barcode_count\tunclassified_count\ttotal" > $raw_files/04_demultiplex_to_combinedBarcodeFastq/summary.tsv
        awk 'NR > 1 {OFS="\t"; if ($2 ~ /^barcode/) barcode_count++; if ($2 == "unclassified") unclassified_count++} END {print barcode_count, unclassified_count, barcode_count + unclassified_count}' \
        $raw_files/03_basecall_to_demultiplex/barcoding_summary.txt >> $raw_files/04_demultiplex_to_combinedBarcodeFastq/summary.tsv

        reads_after_basecalling_passed_demultiplexing=$(awk 'NR>1 { print $3 }' $raw_files/04_demultiplex_to_combinedBarcodeFastq/summary.tsv )
        reads_after_basecalling_passed_demultiplexing_classified=$(awk 'NR>1 { print $1 }' $raw_files/04_demultiplex_to_combinedBarcodeFastq/summary.tsv )
        reads_after_basecalling_passed_demultiplexing_unclassified=$(awk 'NR>1 { print $2 }' $raw_files/04_demultiplex_to_combinedBarcodeFastq/summary.tsv )
 
        percentage_reads_after_basecalling_passed=$(printf "%.2f" $(echo "scale=4; 100*$reads_after_basecalling_passed/$reads_after_basecalling" | bc))
        percentage_reads_after_basecalling_failed=$(printf "%.2f" $(echo "scale=4; 100*$reads_after_basecalling_failed/$reads_after_basecalling" | bc))
        percentage_reads_after_basecalling_passed_demultiplexing_classified=$(printf "%.2f" $(echo "scale=4; 100*$reads_after_basecalling_passed_demultiplexing_classified/$reads_after_basecalling" | bc))
        percentage_reads_after_basecalling_passed_demultiplexing_unclassified=$(printf "%.2f" $(echo "scale=4; 100*$reads_after_basecalling_passed_demultiplexing_unclassified/$reads_after_basecalling" | bc))

        # echo "reads_reported_by_machine $total"
        echo "reads_after_basecalling $reads_after_basecalling" | tee -a $wd/summary.tsv
        echo "reads_after_basecalling_passed $reads_after_basecalling_passed ("$percentage_reads_after_basecalling_passed"%)" | tee -a $wd/summary.tsv
        echo "reads_after_basecalling_failed $reads_after_basecalling_failed ("$percentage_reads_after_basecalling_failed"%)" | tee -a $wd/summary.tsv
        echo "reads_after_basecalling_passed_demultiplexing $reads_after_basecalling_passed_demultiplexing" | tee -a $wd/summary.tsv 
        echo "reads_after_basecalling_passed_demultiplexing_classified $reads_after_basecalling_passed_demultiplexing_classified ("$percentage_reads_after_basecalling_passed_demultiplexing_classified"%)" | tee -a $wd/summary.tsv
        echo "reads_after_basecalling_passed_demultiplexing_unclassified $reads_after_basecalling_passed_demultiplexing_unclassified ("$percentage_reads_after_basecalling_passed_demultiplexing_unclassified"%)" | tee -a $wd/summary.tsv
        log "FINISHED : STEP-06 : creating stat file"
    fi 
###############################################################################
## step-08: run nanoplot
    if [ $parameter_file_data -ne 0 ] ; then 
    if [ -d data/fastq ] ; then 
    if [ -f tmp/parameters/$pipeline.txt ] ; then
        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
        conda activate nanoplot_v1.41.3

        if [ ! -d data/fastq_nanoplot_QC10 ] ; then 
            ( mkdir data/fastq_nanoplot_QC10 ) > /dev/null 2>&1
            
            grep -v "#" tmp/parameters/$pipeline.txt | awk '{print $2}' > tmp/parameters/$pipeline.samples.txt

            for i in $(cat  tmp/parameters/$pipeline.samples.txt ); do
                if [ -f data/fastq/$i.10.fastq.gz ] ; then 
                    if [ ! -f data/fastq_nanoplot_QC10/$i/NanoStats.txt ] ; then
                        log "STARTED : nanoplot for $i"
                        NanoPlot -t 2 --fastq data/fastq/$i.10.fastq.gz -o data/fastq_nanoplot_QC10/$i
                        log "FINISHED : nanoplot for $i"
                        else
                        log "ALREADY FINISHED : nanoplot for $i"
                    fi
                fi
            done

            rm tmp/parameters/$pipeline.samples.txt
        fi

    fi
    fi
    fi
    # data/fastq_nanoplot_QC/isolate_1/Non_weightedHistogramReadlength.html
###############################################################################
## step-09: send report by email (with attachment)
    # echo "sending email"
    # user=$(whoami)
    # user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    # source /home/groups/VEO/tools/email/myenv/bin/activate

    # python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/$pipeline.py -e $user_email

    # deactivate
###############################################################################
## footer
    log "ENDED : $pipeline -------------------"
###############################################################################



###############################################################################
## discarded codes 
###############################################################################
## post-processing
    ## compress fastq files to save the place
        # echo "basecalling finished, compressing data"
        # for i in $(ls /scratch/basecalled/$file/pass/*.fastq | awk -F'/' '{print $NF}'); do
        #     gzip --stdout /scratch/basecalled/$file/pass/$file.fastq > /scratch/basecalled/$file/$file.fastq.gz
        #     rm /scratch/basecalled/$file/pass/$file.fastq
        # done
###############################################################################
## nanoplot and nanoQC
    # source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    # conda activate nanoqc_v0.9.4
    # ## QC by nanoQC_v0.9.4
    # (mkdir $raw_files/04_demultiplex_to_combinedBarcodeFastq/files_barcoded_nanoQC ) > /dev/null 2>&1
    # for barcode in $(cat $raw_files/04_demultiplex_to_combinedBarcodeFastq/list.barcodes.txt) ; do 
    #     nanoQC $raw_files/04_demultiplex_to_combinedBarcodeFastq_zipped/$barcode.fastq.gz
    #     mv nanoQC.html $raw_files/04_demultiplex_to_combinedBarcodeFastq/files_barcoded_nanoQC/$barcode.html
    #     mv nanoQC.log $raw_files/04_demultiplex_to_combinedBarcodeFastq/files_barcoded_nanoQC/$barcode.log
    # done
    # echo "nanoQC is finished, see $raw_files/04_demultiplex_to_combinedBarcodeFastq/files_barcoded_nanoQC/ for results"
###############################################################################