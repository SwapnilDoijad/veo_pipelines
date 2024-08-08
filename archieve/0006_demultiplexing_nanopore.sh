#!/bin/bash
###############################################################################
## installation steps

    ## guppy installation 
    ## mkdir /home/groups/VEO/tools/ont-guppy-cpu/bin/guppy_basecaller
    #   cd /home/groups/VEO/tools/ont-guppy-cpu/bin/guppy_basecaller
    #   https://ontpipeline2.readthedocs.io/en/latest/GetStarted.html
    #   wget https://mirror.oxfordnanoportal.com/software/analysis/ont-guppy-cpu_3.0.3_linux64.tar.gz
    #   tar -xf ont-guppy-cpu_3.0.3_linux64.tar.gz
    #   /home/groups/VEO/tools/ont-guppy-cpu/bin/guppy_basecaller -h

    ## poretool installation
    ## more details:https://poretools.readthedocs.io/en/latest/content/examples.html
    #    conda create -n poretools_v0.6.1a1
    #    conda activate poretools_v0.6.1a1
    #    conda install -c bioconda poretools
    #    poretools -h 

    ## porechop installation
    ## more details: https://github.com/rrwick/Porechop
    #    mkdir /home/groups/VEO/tools/porechop_v0.2.4
    #    cd /home/groups/VEO/tools/porechop_v0.2.4
    #    git clone https://github.com/rrwick/Porechop.git
    #    cd Porechop
    #    make
    #    ./porechop-runner.py -h

    ## nanoplot
    ## more details: https://github.com/wdecoster/NanoPlot
    #   source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    #   conda create -n nanoplot_v1.20.0
    #   conda activate nanoplot_v1.20.0

    ## nanoQC
    ## more details: https://github.com/wdecoster/NanoQC
    #   source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    #   conda create -n nanoqc_v0.9.4
    #   conda activate nanoqc_v0.9.4
###############################################################################
## step-0: preparation

    ## activate conda environment
    #source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    #conda activate poretools_v0.6.1a1

    my_tool_path=/home/groups/VEO/tools/ont-guppy/gpu_v6.5.7_linux64/

    ## find path of the fast5 directory
    fast5_path=$(find . -type d -name "fast5" | sed 's/\.\///g' )
    echo fast5 files found at $fast5_path
###############################################################################
## step-01: basecalling

    if [ ! -d raw_data/basecalled ] ; then
        ##allocate GPU
        salloc -p gpu 

        ## create necessary directories 
        ( rm /scratch/fast5 ) > /dev/null 2>&1
        ( rm /scratch/basecalled ) > /dev/null 2>&1
        ( mkdir -p /scratch/basecalled ) > /dev/null 2>&1
        ( mkdir -p /scratch/fast5 ) > /dev/null 2>&1
        
        ## copy data to scratch folder to process it faster 
        echo "copying data to GPU node to process it faster"
        cp -r $fast5_path /scratch/

        ## run guppy gpu-based basecaller
        $my_tool_path/bin/guppy_basecaller \
        -i /scratch/fast5 \
        --num_callers 20 \
        --cpu_threads_per_caller 1 \
        -s /scratch/basecalled \
        -c $my_tool_path/data/dna_r9.4.1_450bps_fast.cfg

        (mkdir /scratch/basecalled/guppy_log ) > /dev/null 2>&1
        (mv /scratch/basecalled/*.log /scratch/basecalled/guppy_log) > /dev/null 2>&1

        ## compress fastq files to save the place
        echo "basecalling finished, compressing data"
        for i in $(ls /scratch/basecalled/pass/*.fastq | awk -F'/' '{print $NF}'); do
            gzip --stdout /scratch/basecalled/pass/$i.fastq > /scratch/basecalled/$i.fastq.gz
            rm /scratch/basecalled/pass/$i.fastq
        done

        echo "basecalling finished, copying back data from GPU node to working node"
        cp -r /scratch/basecalled raw_data/

        rm -r /scratch/fast5 
        rm -r /scratch/basecalled

        #poretools fastq $fast5_path
    fi
###############################################################################
## step-02: QC
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh

    ## QC by nanoplot_v1.41.3
    if [ ! -d raw_data/basecalled/NanoPlot ]; then 
        echo "running NanoPlot v1.41.3 for QC"
        conda activate nanoplot_v1.41.3
        NanoPlot --summary raw_data/basecalled/sequencing_summary.txt --loglength -o raw_data/basecalled/NanoPlot
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
exit