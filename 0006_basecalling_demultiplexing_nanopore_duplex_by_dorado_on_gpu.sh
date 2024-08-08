#!/bin/bash
###############################################################################
## header
    pipeline=0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"
###############################################################################
## step-01: preparation

    ls $data_directory_pod5_path | sed 's/.pod5//g' > list.pod5.txt
    list=list.pod5.txt

    create_directories_structure_1 $wd
    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0006_basecalling_demultiplexing_nanopore_duplex_by_dorado_on_gpu.sbatch
#######################################################################
## footer
    log "ENDED : $pipeline ----------------------"
###############################################################################

exit 


###############################################################################

###############################################################################
## step-01b: basecalling by dorado (pod5 to .bam)
    ## redoing step-01 as the output from above step (pod5 to fastq) not able to 
    ## process for demultiplexing

    # if [ ! -f $data_path/pod5_basecalled_dorado_duplex/duplex_bam/duplex.bam ] ; then 
    #     ( mkdir -p $data_path/pod5_basecalled_dorado_duplex/duplex_bam ) > /dev/null 2>&1
    #     echo "step-01b: running: basecalling by dorado (pod5 to .bam)"
    #     /home/groups/VEO/tools/dorado/v0.3.1/bin/dorado duplex \
    #     /home/groups/VEO/tools/dorado/v0.3.1/models/dna_r10.4.1_e8.2_400bps_hac@v4.2.0 \
    #     $data_path/pod5/ > $data_path/pod5_basecalled_dorado_duplex/duplex_bam/duplex.bam
    #     echo "step-01b: finished: basecalling by dorado (pod5 to .bam)"
    #     else
    #     echo "step-01b: already finsihed: basecalling by dorado (pod5 to .bam)"
    # fi 

    # ## sort .bam file 
    # if [ ! -f $data_path/pod5_basecalled_dorado_duplex/duplex_bam_sorted/duplex_sorted.bam ] ; then
    #     echo "step-01b: sorting .bam file: runnig"
    #     ( mkdir -p $data_path/pod5_basecalled_dorado_duplex/duplex_bam_sorted ) > /dev/null 2>&1
    #     /home/groups/VEO/tools/samtools/v1.17/bin/samtools sort \
    #     $data_path/pod5_basecalled_dorado_duplex/duplex_bam/duplex.bam \
    #     -o $data_path/pod5_basecalled_dorado_duplex/duplex_bam_sorted/duplex_sorted.bam
    #     echo "step-01b: sorting .bam file: finished"
    #     else
    #     echo "step-01b: sorting .bam file: already finished "
    # fi 

###############################################################################
## step-02: demultiplexing 

    if [ ! -d results/pod5_basecalled_dorado_duplex_demultiplexed ] ; then 
        echo "step-02: demultiplexing : running "

        ## run guppy cpu baracoder

        /home/groups/VEO/tools/ont-guppy/v6.5.7_cpu/bin/guppy_barcoder \
        -t 10 \
        -i $data_path/pod5_basecalled_dorado_duplex/seperate/ \
        -s results/pod5_basecalled_dorado_duplex_demultiplexed/ \
        --barcode_kits SQK-NBD114-96  --enable_trim_barcodes --trim_adapters
        else
        echo "step-02: demultiplexing : already finished "
    fi 

exit
###############################################################################

    mkdir $data_path/pod5_basecalled_dorado_duplex_demultiplexed
    #if [ ! -d raw_data/basecalled ] ; then
        for i in $(ls $data_path/fast5 ); do
            echo $i 
            /home/groups/VEO/scripts_for_users/supplementary_scripts/0007_demultiplexing_nanopore_demultiplexing_by_guppy_cpu.sbatch
            ( sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0006_demultiplexing_nanopore_basecalling_cpu.sbatch -file $i -dir_path $data_path ) > /dev/null 2>&1 
        done
    #fi

exit
###############################################################################
## post-processing
        ## compress fastq files to save the place
        echo "basecalling finished, compressing data"
        for i in $(ls /scratch/basecalled/$file/pass/*.fastq | awk -F'/' '{print $NF}'); do
            gzip --stdout /scratch/basecalled/$file/pass/$file.fastq > /scratch/basecalled/$file/$file.fastq.gz
            rm /scratch/basecalled/$file/pass/$file.fastq
        done

        echo "basecalling finishedfor $file, copying back data from GPU node to working node"
        cp  /scratch/basecalled/$file/$file.fastq.gz raw_data/
###############################################################################
## step-03: QC
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh

    ## QC by nanoplot_v1.41.3
    if [ ! -d raw_data/basecalled/NanoPlot ]; then 
        echo "running NanoPlot v1.41.3 for QC"
        conda activate nanoplot_v1.41.3
        #NanoPlot --summary raw_data/basecalled/sequencing_summary.txt --loglength -o raw_data/basecalled/NanoPlot
        NanoPlot
        echo "NanoPlot for QC is finished, see raw_data/basecalled/NanoPlot/NanoPlot-report.html file"
    fi

    ## QC by nanoQC_v0.9.4
    if [ ! -d raw_data/basecalled/nanoQC ]; then 
        echo "running nanoQC v0.9.4 for QC"
        (mkdir raw_data/basecalled/nanoQC ) > /dev/null 2>&1
        conda activate nanoqc_v0.9.4
        for i in $(ls raw_data/basecalled/pass/*.fastq | awk -F'/' '{print $NF}'); do
            echo "running nanoQC for $i"
            gzip --stdout raw_data/basecalled/pass/$i > raw_data/basecalled/pass/$i.gz
            nanoQC raw_data/basecalled/pass/$i.gz
            mv nanoQC.html raw_data/basecalled/nanoQC/$i.html
            mv nanoQC.log raw_data/basecalled/nanoQC/$i.log
            #rm raw_data/basecalled/pass/$i.fastq
        done
        echo "nanoQC is finished, see raw_data/basecalled/nanoQC/ for results"
    fi
###############################################################################
echo "script 0006 demultiplexing nanopore-duplex by dorado ended ---------------------" 
###############################################################################