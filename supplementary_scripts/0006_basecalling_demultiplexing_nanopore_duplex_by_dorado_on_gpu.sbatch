#!/bin/bash
###############################################################################
#SBATCH --job-name 0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu
#SBATCH --partition=gpu,gpu-veo,gpu-test
#SBATCH --output results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/tmp/slurm/%j.out
#SBATCH --error results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
############################################################################### 
## header
    pipeline=0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED SBATCH: $pipeline --------------------"
    module load nvidia/cuda/11.7

    kit_name=$( grep my_kit $parameters | awk '{print $2}' )
    type_of_sequencing=$( grep my_type_of_sequencing $parameters | awk '{print $2}' )
    duplex=$( grep my_duplex_choise $parameters | awk '{print $2}' )
    barcode_sample_data=$( cat $wd/tmp/barcode_sample.txt | wc -l )
    data_directory_pod5_path=$(grep "my_pod5_file_path" $parameters | awk '{print $2}')
    trim_adapter_barcode_primer=$( grep my_trim_adapter_barcode_primer $parameters | awk '{print $2}' )
    demultiplex_amplicon=$( grep my_demultiplex_amplicon $parameters | awk '{print $2}' )
    dorado=/home/groups/VEO/tools/dorado/v0.9.1/bin/dorado
    # dorado=/home/groups/VEO/tools/dorado/v0.6.0/bin/dorado
    samtools=/home/groups/VEO/tools/samtools/v1.17/bin/samtools
    models_directory=/home/groups/VEO/tools/dorado/v0.9.1/models/
    ## 2025-02-07 14:06:48 
    ## @Swapnil : pod5 inspect debug <file.pod5> | grep sequencing_kit     

    log "kit_name: $kit_name type_of_sequencing: $type_of_sequencing duplex: $duplex"
    log "data_directory_pod5_path: $data_directory_pod5_path"
    log "trim_adapter_barcode_primer: $trim_adapter_barcode_primer"
    log "demultiplex_amplicon: $demultiplex_amplicon"
    log "dorado: $dorado"
    log "samtools: $samtools"

############################################################################### 
## step-01: 01_pod5_to_fastq amplicon

    if [ $type_of_sequencing == "amplicon" ] ; then
        ## ONLY basecalling (need to run seperate demultiplication step)
        ## its important to create .bam file first and then fastq files (more info stored in bam)
        ## better for amplicon sequencing
        ( mkdir -p $raw_files/01_pod5_to_fastq ) > /dev/null 2>&1

        ## if adapter_barcode_primer is not trimmed out, then there is information for demultiplexing. 
        if [ "$trim_adapter_barcode_primer" == "No" ] ; then 
            # if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz ] ; then 
                log "STARTED: 01_pod5_to_fastq: ONLY basecalling"
                log "data_directory_pod5_path: $data_directory_pod5_path"

                ## basecalling (all nucleotides, without trimming - to keep the barcodes, adapters and primers)
                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam ]; then
                    $dorado basecaller /home/groups/VEO/tools/dorado/v0.9.1/models/dna_r10.4.1_e8.2_400bps_sup@v4.3.0 \
                    --no-trim \
                    $data_directory_pod5_path/ \
                    > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam
                fi

                ## convert no_trim.bam to no_trim.bam.fastq.gz
                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz ]; then
                    $samtools \
                    view -@10 -O fastq \
                    $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam \
                    | pigz -9 > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz
                fi

                ## count reads in raw_reads.no_trim.fastq.gz.read_count
                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_count ] ; then
                    log "STARTED: counting reads in raw_reads.no_trim.fastq.gz"

                    count_reads_from_fastq \
                    $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz \
                    > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_count
                fi

                ## read distribution
                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_distribution ] ; then 
                    log "STARTED: read distribution"

                    python3.9 $suppl_scripts/utilities/fastq_read_distribution.py \
                    -i $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz \
                    -o $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_distribution
                fi

                ## 2025-04-04 10:31:40  optional: for demultiplexing (May not needed for amplicon seqeuncing 0991/0992 pipeline will identify the barcodes) 
                    ## automatic demultiplexing gives very low reads per bin even though v0.9.1 is used
                if [ $demultiplex_amplicon == "Yes" ] ; then 
                    ## optional: get read ids from pod5 file
                        # source /home/groups/VEO/tools/pod5/v0.2.2/bin/activate
                        # python3 $suppl_scripts/utilities/get_read_ids_from_pod5.py \
                        # -d $data_directory_pod5_path/ \
                        # -o $wd/pod5.reads_ids
                        # deactivate

                    ## optional: get read ids from bam file
                        # $samtools \
                        # view \
                        # $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam \
                        # | awk '{OFS="\t"; print $10=""; $11="" ; print $0}' \
                        # > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam.read_ids
                    
                        ## remove blank lines 
                        # grep -v '^$' $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam.read_ids \
                        # > temp && mv temp \
                        # $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam.read_ids

                    if [ ! -d $raw_files/01_pod5_to_fastq/demultiplexed_fastq ]; then 
                        log "STARTED: demultiplexing"

                        mkdir $raw_files/01_pod5_to_fastq/demultiplexed_fastq

                        $dorado demux \
                        --emit-fastq \
                        --output-dir $raw_files/01_pod5_to_fastq/demultiplexed_fastq \
                        --kit-name $kit_name \
                        $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam
                    fi

                    ## compress fastq files
                    if [ ! -f $raw_files/01_pod5_to_fastq/demultiplexed_fastq_read_count.tsv ] ; then
                        log "STARTED: compressing fastq files"
                        for i in $(ls $raw_files/01_pod5_to_fastq/demultiplexed_fastq/ ); do 
                            log "COMPRESSING: $i"

                            pigz -9 -c $raw_files/01_pod5_to_fastq/demultiplexed_fastq/$i \
                            > $raw_files/01_pod5_to_fastq/demultiplexed_fastq/$i.gz 

                            # rm -rf $raw_files/01_pod5_to_fastq/demultiplexed_fastq/$i

                            read_count=$(count_reads_from_fastq $raw_files/01_pod5_to_fastq/demultiplexed_fastq/$i.gz)
                            echo -e "$i\t$read_count" | tee -a $raw_files/01_pod5_to_fastq/demultiplexed_fastq_read_count.tsv
                        done

                        else
                        log "ALREADY FINISHED: compressing fastq files"
                    fi

                    ## rename files
                    if [ $barcode_sample_data -ne 0 ] ; then 
                    if  [ ! -d $raw_files/01_pod5_to_fastq/demultiplexed_fastq_renamed ] ; then 
                        if [ -f tmp/parameters/$pipeline.txt ] ; then 
                            log "renaming files"

                            mkdir $raw_files/01_pod5_to_fastq/demultiplexed_fastq_renamed > /dev/null 2>&1

                            awk '{print $1}' $wd/tmp/barcode_sample.txt > $wd/tmp/$pipeline.barcode.txt
                            awk '{print $2}' $wd/tmp/barcode_sample.txt > $wd/tmp/$pipeline.samples.txt

                            echo -e "barcode\tids\traw_reads\tQC_filtered_reads" > $wd/reads_count.txt

                            exec 3<$wd/tmp/$pipeline.barcode.txt
                            exec 4<$wd/tmp/$pipeline.samples.txt
                            while read barcode <&3; read ids <&4 ; do 
                                log "$barcode.fastq.gz renamed as $ids.fastq.gz"
                                cp $raw_files/01_pod5_to_fastq/demultiplexed_fastq_QC10/*_"$kit_name"_"$barcode".fastq.gz \
                                $raw_files/01_pod5_to_fastq/demultiplexed_fastq_renamed/$ids.fastq.gz

                                raw_reads=$( count_reads_from_fastq $raw_files/01_pod5_to_fastq/demultiplexed_fastq/*_"$kit_name"_"$barcode".fastq )
                                QC_filtered_reads=$( count_reads_from_fastq $raw_files/01_pod5_to_fastq/demultiplexed_fastq_QC10/*_"$kit_name"_"$barcode".fastq.gz )
                                echo $barcode $ids $raw_reads $QC_filtered_reads | tee -a $wd/reads_count.txt
                            done

                            else
                            log "$wd/tmp/$pipeline.barcode.txt and $wd/tmp/$pipeline.barcode_corresponding_ids.txt not found, skipping"
                        fi
                        else
                        log "$raw_files/01_pod5_to_fastq/demultiplexed_fastq_renamed already exists"
                    fi
                    fi

                    ## convert bam to to fastq
                    # if [ ! -d $raw_files/01_pod5_to_fastq/demultiplexed_fastq ]; then 
                    #     ( mkdir $raw_files/01_pod5_to_fastq/demultiplexed_fastq ) > /dev/null 2>&1
                    #     for bam_file_id in $(ls $raw_files/01_pod5_to_fastq/demultiplexed | sed 's/\.bam//g' ); do 
                    #         $samtools \
                    #         view -@40 -O fastq \
                    #         $raw_files/01_pod5_to_fastq/demultiplexed/"$bam_file_id".bam \
                    #         | pigz -9 \
                    #         > $raw_files/01_pod5_to_fastq/demultiplexed_fastq/"$bam_file_id".fastq.gz
                    #     done 
                    # fi

                    ## fastq to fastq_10
                    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 
                    if [ ! -d $raw_files/01_pod5_to_fastq/demultiplexed_fastq_QC10 ]; then
                        mkdir $raw_files/01_pod5_to_fastq/demultiplexed_fastq_QC10

                        for i in $(ls $raw_files/01_pod5_to_fastq/demultiplexed_fastq/ ); do  
                            log "STARTED: demultiplexing: fastq to fastq_10: $i"
                            cat $raw_files/01_pod5_to_fastq/demultiplexed_fastq/$i.fastq \
                            | chopper -t 100 -q 10 \
                            > $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/$i.10.fastq
                        done
                    fi
                    conda deactivate
                    exit 
                    
                    ## count reads
                    for i in $(ls $raw_files/01_pod5_to_fastq/demultiplexed/ ); do 
                        number_of_reads=$( $samtools view \
                        -c $raw_files/01_pod5_to_fastq/demultiplexed/$i )
                        echo $i $number_of_reads | tee -a $wd/reads_count.bam.txt
                    done 

                    # log "FINISHED: 01_pod5_to_fastq: ONLY basecalling"
                    # else
                    # log "ALREADY FINISHED: 01_pod5_to_fastq: ONLY basecalling" 
                # fi
            fi

        ## 2025-02-14 14:58:57 @Swapnil : If you trim the barcodes, adapters and primers, you will lose the information about the barcodes and adapters.
        ## and can't demultiplex the reads. So, it is important to keep the barcodes, adapters and primers in the reads.
        elif [ "$trim_adapter_barcode_primer" == "Yes" ] ; then
            if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz ] ; then 
                log "STARTED: 01_pod5_to_fastq: basecalling "

                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.bam ]; then

                    $dorado basecaller sup \
                    $data_directory_pod5_path/ \
                    > $raw_files/01_pod5_to_fastq/raw_reads.bam

                fi

                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz ]; then
                    $samtools \
                    view -@10 -O fastq \
                    $raw_files/01_pod5_to_fastq/raw_reads.bam \
                    | pigz -9 > $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz
                fi

                ## 2025-02-14 14:58:57 @Swapnil : No point runnig demultiplexing. 
                
                    ## demultiplexing
                    # if [ ! -d $raw_files/01_pod5_to_fastq/demultiplexed ]; then
                    #     ( mkdir $raw_files/01_pod5_to_fastq/demultiplexed ) > /dev/null 2>&1
                    #     $dorado demux \
                    #     --output-dir $raw_files/01_pod5_to_fastq/demultiplexed \
                    #     --kit-name $kit_name \
                    #     $raw_files/01_pod5_to_fastq/raw_reads.bam
                    # fi

                    # ## convert bam to to fastq
                    # mkdir $raw_files/01_pod5_to_fastq/demultiplexed_fastq_gz > /dev/null 2>&1
                    # for i in $(ls $raw_files/01_pod5_to_fastq/demultiplexed/ ); do
                    #     log "STARTED: demultiplexing: bam to fastq: $i"
                    #     $samtools \
                    #     view -@10 -O fastq \
                    #     $raw_files/01_pod5_to_fastq/demultiplexed/$i \
                    #     | pigz -9 >  $raw_files/01_pod5_to_fastq/demultiplexed_fastq_gz/$i.fastq.gz

                    #     reads_count=$(count_reads_from_fastq $raw_files/01_pod5_to_fastq/demultiplexed_fastq_gz/$i.fastq.gz )

                    #     echo -e "$i\t$read_count" | tee -a $raw_files/01_pod5_to_fastq/demultiplexed_fastq_gz_read_count.tsv
                    # done

                ## count reads in raw_reads.fastq.gz.read_count
                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz.read_count ] ; then
                    count_reads_from_fastq $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz \
                    > $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz.read_count
                fi

                ## read distribution
                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz.read_distribution ] ; then 
                    python3.9 $suppl_scripts/utilities/fastq_read_distribution.py \
                    -i $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz \
                    -o $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz.read_distribution
                fi

                ## count reads
                for i in $(ls $raw_files/01_pod5_to_fastq/demultiplexed/ ); do 
                    number_of_reads=$( $samtools view \
                    -c $raw_files/01_pod5_to_fastq/demultiplexed/$i )
                    echo $i $number_of_reads | tee -a $wd/reads_count.bam.txt
                done 

                ## create histogram
                if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.png ] ; then
                    source /home/groups/VEO/tools/biopython/myenv/bin/activate
                    
                    python $suppl_scripts/plots/histogram.double_column_input.py \
                    -i  $raw_files/01_pod5_to_fastq/raw_reads.fastq.gz.read_distribution
                    -r 450

                    deactivate
                fi
            fi
        fi
    fi


###############################################################################
## step-02: 02_pod5_to_demux genome
    ## this step the barcodes and adapters will be trimmed and its important for the genome sequencing
    
    if [[ $type_of_sequencing == "genome" ]] ; then 
    if [[ $duplex == "No" ]] ; then
        ## basecalling + in line demultiplexing
        # if [ ! -f $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam ] ; then
            log "STARTED: 02_pod5_to_demux : basecalling + in line demultiplexing"

            ( mkdir -p $raw_files/02_pod5_to_demultiplex ) > /dev/null 2>&1
            ( mkdir -p $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq ) > /dev/null 2>&1
            ( mkdir -p $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10 ) > /dev/null 2>&1

                            ## 240706 Swapnil: I think direct demultiplexing is not possible with dorado
                            ## 1 create basecalled .bam file 
                            ## 2 demultiplex bam 
                            ## 3 convert individual bam to fastq
                                    ## depreciated codes
                                        # ( mkdir -p $raw_files/02_pod5_to_demultiplex/demultiplexed_bam ) > /dev/null 2>&1
                                        # $dorado demux \
                                        # --output-dir $raw_files/02_pod5_to_demultiplex/demultiplexed_bam \
                                        # --kit-name $kit_name \
                                        # $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam
            
            if [ ! -f $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam ]; then
                log "BASECALLING: generating $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam"

                $dorado \
                basecaller sup \
                $data_directory_pod5_path/ \
                > $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam

                log "FINISHED BASECALLING: generating $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam"
            fi

            $dorado demux \
            --output-dir $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq \
            --emit-fastq --kit-name $kit_name \
            $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam

            ## 240706 Swapnil: add stept to compress $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq and change below steps accordinly 
            ## QC filtering
            source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 
            for i in $( ls $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq | sed 's/\.fastq//g' ); do
                cat $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq/$i.fastq \
                | chopper -t 100 -q 10 \
                > $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/$i.fastq
                # | pigz -9 -c > $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/$i.fastq.gz ## for rasusa subsampling need fastq and not fastq.gz
            done 

            ## compress file (we need both uncompressed file for Rasusa subsampling and compressed file for storage)
            for i in $( ls $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/*.fastq ) ; do
                log "COMPRESSING: $i"
                pigz -9 -c "$i" > "$i".gz
            done

            log "FINISHED: 02_pod5_to_demux : basecalling + in line demultiplexing"
            else
            log "ALREADY FINISHED: 02_pod5_to_demux : basecalling + in line demultiplexing"
        # fi 
    fi 
    fi

###############################################################################  
## step-03: 03_pod5_to_demux_DUPLEX duplex
    ## notes: trim option is not available in dorado duplex

    if [[ $type_of_sequencing == "genome" ]] ; then 
    if [[ $duplex == "Yes" ]] ; then
        # if [ ! -f $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam ] ; then
        #     log "STARTED: 03_pod5_to_demux_DUPLEX"

            ( mkdir -p $raw_files/03_pod5_to_demux_DUPLEX ) > /dev/null 2>&1

            # if [ ! -f $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.simplex_with_offsprings.fastq.gz ]; then

                if [ ! -f $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam ]; then 
                    $dorado \
                    duplex /home/groups/VEO/tools/dorado/v0.9.1/models/dna_r10.4.1_e8.2_400bps_sup@v4.3.0 \
                    $data_directory_pod5_path/ \
                    > $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam
                fi 

                $samtools \
                view -@10 -ddx:1 -O fastq \
                $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam \
                | pigz -9 -c \
                > $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.duplex.fastq.gz

                $samtools \
                view -@10  -ddx:0 -O fastq \
                $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam \
                | pigz -9 -c \
                > $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.simplex.fastq.gz

                $samtools \
                view -@10 -ddx:-1 -O fastq \
                $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam \
                | pigz -9 -c \
                > $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.simplex_with_offsprings.fastq.gz

                # $dorado \
                # dorado summary \
                # $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam \
                # > $raw_files/03_pod5_to_demux_DUPLEX/raw_reads.bam.summary.tsv

                echo -"simplex_readssimplex_with_offsprings duplex" | tr ' ' '\t' > $raw_files/03_pod5_to_demux_DUPLEX/reads_count.fastq.txt
                simplex_reads=$(count_reads_from_fastq $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.simplex.fastq.gz)
                simplex_with_offsprings=$(count_reads_from_fastq $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.simplex_with_offsprings.fastq.gz)
                duplex=$(count_reads_from_fastq $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.duplex.fastq.gz)
                echo "$simplex_reads $simplex_with_offsprings $duplex" | tr ' ' '\t' | tee -a $raw_files/03_pod5_to_demux_DUPLEX/reads_count.fastq.txt


                ## demultiplexing
                mkdir -p $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex
                $dorado demux \
                --output-dir $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex \
                --emit-fastq --kit-name $kit_name \
                $raw_files/03_pod5_to_demux_DUPLEX/raw_reads_duplex.duplex.fastq.gz

                ## QC filtering 
                mkdir -p $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex_QC10
                source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 
                for i in $( ls $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex | sed 's/\.fastq//g' ); do
                    cat $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex/$i.fastq \
                    | chopper -t 100 -q 10 \
                    | pigz -9 -c > $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex_QC10/$i.fastq.gz ## for rasusa subsampling need fastq and not fastq.gz
                    # > $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/$i.fastq
                done 

                exec 3<$wd/tmp/$pipeline.barcode.txt
                exec 4<$wd/tmp/$pipeline.samples.txt
                while read barcode <&3; read ids <&4 ; do 
                    echo "$barcode.fastq.gz renamed as $ids.fastq.gz"
                    cp $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex_QC10/*_"$kit_name"_"$barcode".fastq.gz \
                    $raw_files/fastq/$ids.fastq.gz

                    raw_reads=$( count_reads_from_fastq $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex/*_"$kit_name"_"$barcode".fastq )
                    QC_filtered_reads=$( count_reads_from_fastq $raw_files/03_pod5_to_demux_DUPLEX/demultiplexed_fastq_duplex_QC10/*_"$kit_name"_"$barcode".fastq.gz )
                    echo $barcode $ids $raw_reads $QC_filtered_reads | tee -a $wd/reads_count.txt
                done



            # fi

        #     log "FINISHED: 03_pod5_to_demux_DUPLEX"
        #     else
        #     log "ALREADY FINISHED: 03_pod5_to_demux_DUPLEX"
        # fi
    fi
    fi

###############################################################################
exit
## step-04: renaming and counting reads
    if [ $barcode_sample_data -ne 0 ] ; then 
    if  [ ! -d $raw_files/fastq ] ; then 
        if [ -f tmp/parameters/$pipeline.txt ] ; then 
            mkdir $raw_files/fastq > /dev/null 2>&1
            log "renaming files"
            awk '{print $1}' $wd/tmp/barcode_sample.txt > $wd/tmp/$pipeline.barcode.txt
            awk '{print $2}' $wd/tmp/barcode_sample.txt > $wd/tmp/$pipeline.samples.txt

            ( mkdir -p $raw_files/fastq ) > /dev/null 2>&1
            echo -e "barcode\tids\traw_reads\tQC_filtered_reads" > $wd/reads_count.txt

            exec 3<$wd/tmp/$pipeline.barcode.txt
            exec 4<$wd/tmp/$pipeline.samples.txt
            while read barcode <&3; read ids <&4 ; do 
                echo "$barcode.fastq.gz renamed as $ids.fastq.gz"
                cp $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/*_"$kit_name"_"$barcode".fastq.gz \
                $raw_files/fastq/$ids.fastq.gz

                raw_reads=$( count_reads_from_fastq $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq/*_"$kit_name"_"$barcode".fastq )
                QC_filtered_reads=$( count_reads_from_fastq $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/*_"$kit_name"_"$barcode".fastq.gz )
                echo $barcode $ids $raw_reads $QC_filtered_reads | tee -a $wd/reads_count.txt
            done

            else
            log "$wd/tmp/$pipeline.barcode.txt and $wd/tmp/$pipeline.barcode_corresponding_ids.txt not found, skipping"
        fi
        else
        log "$raw_files/fastq already exists"
    fi
    fi

###############################################################################
    log "FINISHED SBATCH: $pipeline --------------------"
###############################################################################