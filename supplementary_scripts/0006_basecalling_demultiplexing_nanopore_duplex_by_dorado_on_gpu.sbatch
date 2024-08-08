#!/bin/bash
###############################################################################
#SBATCH --job-name 0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu
#SBATCH --partition=gpu
#SBATCH --output results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/tmp/slurm/%j.out
#SBATCH --error results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/tmp/slurm/%j.err
#SBATCH --gres=gpu:1
############################################################################### 
## header
    pipeline=0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED SBATCH: $pipeline --------------------"
    module load nvidia/cuda/11.7

    kit_name=$( grep my_kit_name $parameters | awk '{print $2}' )
    type_of_sequencing=$( grep my_type_of_sequencing $parameters | awk '{print $2}' )
    duplex=$( grep my_duplex_choise $parameters | awk '{print $2}' )

    log "kit_name: $kit_name type_of_sequencing: $type_of_sequencing duplex: $duplex"
    log "data_directory_pod5_path: $data_directory_pod5_path"
###############################################################################
## step-01: 01_pod5_to_fastq amplicon

    if [[ $type_of_sequencing == "amplicon" ]] ; then 
        ## ONLY basecalling (need to run seperate demultiplication step)
        ## its importnat to create .bam file first and then fastq files (more info stored in bam)
        ## better for amplicon sequencing
        if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz ] ; then 
            log "STARTED: 01_pod5_to_fastq: ONLY basecalling"

            ( mkdir -p $raw_files/01_pod5_to_fastq ) > /dev/null 2>&1
            log "data_directory_pod5_path: $data_directory_pod5_path"

            if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam ]; then
                /home/groups/VEO/tools/dorado/v0.6.0/bin/dorado basecaller sup \
                --no-trim \
                $data_directory_pod5_path/ \
                > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam
            fi

            if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz ]; then
                /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                view -@10 -O fastq \
                $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam \
                | gzip -9 > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz
            fi

            if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_count ] ; then
                count_reads_from_fastq $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz \
                > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_count
            fi

            if [ ! -f $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_distribution ] ; then 
                python $suppl_scripts/utilities/fastq_read_distribution.py \
                -i $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz \
                -o $raw_files/01_pod5_to_fastq/raw_reads.no_trim.fastq.gz.read_distribution
            fi

            ## optional: get read ids from pod5 file
                # source /home/groups/VEO/tools/pod5/v0.2.2/bin/activate
                # python3 $suppl_scripts/utilities/get_read_ids_from_pod5.py \
                # -d $data_directory_pod5_path/ \
                # -o $wd/pod5.reads_ids
                # deactivate

            ## optional: get read ids from bam file
                # /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                # view \
                # $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam \
                # | awk '{OFS="\t"; print $10=""; $11="" ; print $0}' \
                # > $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam.read_ids
            
                ## remove blank lines 
                # grep -v '^$' $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam.read_ids \
                # > temp && mv temp \
                # $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam.read_ids

            ## optional: for demultiplexing (not needed for amplicon)

                # ( mkdir $raw_files/01_pod5_to_fastq/demultiplexed ) > /dev/null 2>&1
                # /home/groups/VEO/tools/dorado/v0.6.0/bin/dorado demux \
                # --output-dir $raw_files/01_pod5_to_fastq/demultiplexed \
                # --kit-name $kit_name \
                # $raw_files/01_pod5_to_fastq/raw_reads.no_trim.bam

            ## convert bam to to fastq
            if [ ! -d $raw_files/01_pod5_to_fastq/demultiplexed_fastq ]; then 
                ( mkdir $raw_files/01_pod5_to_fastq/demultiplexed_fastq ) > /dev/null 2>&1
                for bam_file_id in $(ls $raw_files/01_pod5_to_fastq/demultiplexed | sed 's/\.bam//g' ); do 
                    /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                    view -@40 -O fastq \
                    $raw_files/01_pod5_to_fastq/demultiplexed/"$bam_file_id".bam \
                    | gzip -9 \
                    > $raw_files/01_pod5_to_fastq/demultiplexed_fastq/"$bam_file_id".fastq.gz
                done 
            fi

            log "FINISHED: 01_pod5_to_fastq: ONLY basecalling"
            else
            log "ALREADY FINISHED: 01_pod5_to_fastq: ONLY basecalling" 
        fi
    fi

###############################################################################
## step-02: 02_pod5_to_demux genome
    ## this step the barcodes and adapters will be trimmed and its important for the genome sequencing
    
    if [[ $type_of_sequencing == "genome" ]] ; then 
        ## basecalling + in line demultiplexing
        # if [ ! -f $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam ] ; then
        #     log "STARTED: 02_pod5_to_demux : basecalling + in line demultiplexing"

            ( mkdir -p $raw_files/02_pod5_to_demultiplex ) > /dev/null 2>&1
            ( mkdir -p $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq ) > /dev/null 2>&1
            ( mkdir -p $raw_files/02_pod5_to_demultiplex/demultiplexed_bam ) > /dev/null 2>&1

            ## 240706 Swapnil: I think direct demultiplexing is not possible with dorado
            ## 1 create basecalled .bam file 
            ## 2 demultiplex bam 
            ## 3 convert individual bam to fastq


            # /home/groups/VEO/tools/dorado/v0.6.0/bin/dorado \
            # basecaller sup \
            # $data_directory_pod5_path/ \
            # > $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam

            # /home/groups/VEO/tools/dorado/v0.6.0/bin/dorado demux \
            # --output-dir $raw_files/02_pod5_to_demultiplex/demultiplexed_bam \
            # --kit-name $kit_name \
            # $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam

            # /home/groups/VEO/tools/dorado/v0.6.0/bin/dorado demux \
            # --output-dir $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq \
            # --emit-fastq --kit-name $kit_name \
            # $raw_files/02_pod5_to_demultiplex/raw_reads.for_demux.bam

            ## 240706 Swapnil: add stept to compress $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq and change below steps accordinly 
            ## QC filtering
            mkdir $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10
            source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 
            for i in $( ls $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq | sed 's/\.fastq//g' ); do
                cat $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq/$i.fastq \
                | chopper -t 100 -q 10 \
                > $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/$i.fastq
                # | gzip > $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/$i.fastq.gz ## for rasusa subsampling need fastq and not fastq.gz
            done 

            ## count reads
            for i in $( ls $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq | sed 's/\.fastq//g' ); do
                raw_reads=$( count_reads_from_fastq zcat $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq/$i.fastq.gz )
                QC_filtered_reads=$( count_reads_from_fastq $raw_files/02_pod5_to_demultiplex/demultiplexed_fastq_QC10/$i.fastq.gz )
                echo $i $raw_reads $QC_filtered_reads | tee -a $wd/reads_count.txt
            done 

        #     log "FINISHED: 02_pod5_to_demux : basecalling + in line demultiplexing"
        #     else
        #     log "ALREADY FINISHED: 02_pod5_to_demux : basecalling + in line demultiplexing"
        # fi 
    fi 

    ## 240725: Swapnil : need to update below script for the stat

    	for i in $(ls results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/raw_files/01_pod5_to_fastq/demultiplexed/ ); do 
            number_of_reads=$( /home/groups/VEO/tools/samtools/v1.17/bin/samtools view \
            -c results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/raw_files/01_pod5_to_fastq/demultiplexed/$i )
            echo $i $number_of_reads | tee -a $wd/reads_count.bam.txt
	    done 

    	for i in $(ls results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/raw_files/01_pod5_to_fastq/demultiplexed_fastq/ ); do 
            number_of_reads=$( count_reads_from_fastq results/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu/raw_files/01_pod5_to_fastq/demultiplexed_fastq/$i )
            echo $i $number_of_reads | tee -a $wd/reads_count.fastq.txt
	    done 
###############################################################################  
## step-03: 03_pod5_to_demux duplex
    ## notes: trim option is not available in dorado duplex

    if [[ $type_of_sequencing == "genome" ]] ; then 
    if [[ $duplex == "yes" ]] ; then
        if [ ! -f $raw_files/03_pod5_to_demux/raw_reads.bam ] ; then
            log "STARTED: 03_pod5_to_demux"

            ( mkdir -p $raw_files/03_pod5_to_demux ) > /dev/null 2>&1

            if [ ! -f $raw_files/03_pod5_to_demux/$i.fastq.gz ]; then

                /home/groups/VEO/tools/dorado/v0.6.0/bin/dorado \
                duplex sup \
                $data_directory_pod5_path/ 
                > $raw_files/03_pod5_to_demux/raw_reads.bam

                /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                view -@10 -ddx:1 -O fastq \
                $raw_files/03_pod5_to_demux/raw_reads.bam \
                | gzip -9 \
                > $raw_files/03_pod5_to_demux/raw_reads_duplex.duplex.fastq.gz

                /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                view -@10  -ddx:0 -O fastq \
                $raw_files/03_pod5_to_demux/raw_reads.bam \
                | gzip -9 \
                > $raw_files/03_pod5_to_demux/raw_reads_duplex.simplex.fastq.gz

                /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                view -@10 -ddx:-1 -O fastq \
                $raw_files/03_pod5_to_demux/raw_reads.bam \
                | gzip -9 \
                > $raw_files/03_pod5_to_demux/raw_reads_duplex.simplex_with_offsprings.fastq.gz

                # /home/groups/VEO/tools/dorado/v0.6.0/bin/dorado \
                # dorado summary \
                # $raw_files/03_pod5_to_demux/raw_reads.bam \
                # > $raw_files/03_pod5_to_demux/raw_reads.bam.summary.tsv
            fi

            log "FINISHED: 03_pod5_to_demux"
            else
            log "ALREADY FINISHED: 03_pod5_to_demux"
        fi
    fi
    fi 
###############################################################################
    log "FINISHED SBATCH: $pipeline --------------------"
###############################################################################
