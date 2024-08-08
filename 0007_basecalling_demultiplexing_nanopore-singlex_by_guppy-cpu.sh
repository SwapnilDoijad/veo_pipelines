#!/bin/bash
###############################################################################
## 0007 demultiplexing nanopore
###############################################################################
## step-00: preparation

    ## tool path
    tool_path=/home/groups/VEO/tools/ont-guppy/v6.5.7_cpu

    if [ -f result_summary.read_me.txt ]; then
        pod5_file_path=$(grep pod5 result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide pod5_file_path"
        echo "for e.g., data/nanopore/pod5"
        read pod5_file_path
    fi
    echo pod5_file_path: $pod5_file_path

    dir_path=$( echo $pod5_file_path | awk '{sub(/\/[^/]+$/, ""); print}' )
    echo dir_path: $dir_path

    ( mkdir -p results/0007_basecalling_demultiplexing_nanopore-singlex_by_guppy-cpu/tmp ) > /dev/null 2>&1

###############################################################################
## step-01: converting pod5 to fast5

    if [ ! -d $dir_path/pod5_fast5 ] ; then 

        ( mkdir -p $dir_path/pod5_fast5 ) > /dev/null 2>&1 
        ( mkdir -p tmp/sbatch ) > /dev/null 2>&1 
        ( mkdir -p tmp/slurm ) > /dev/null 2>&1 

        ## run pod5
        for i in $( ls $pod5_file_path ); do 
            echo "pod5 to fast5 conversion started for $i"
            cp /home/groups/VEO/scripts_for_users/supplementary_scripts/0007_demultiplexing_nanopore_pod5.sbatch tmp/sbatch/$i.sbatch ;
            echo "srun pod5 convert to_fast5 $pod5_file_path/$i -t 40 -o $dir_path/pod5_fast5" >> tmp/sbatch/$i.sbatch ;
            ( sbatch tmp/sbatch/$i.sbatch ) > /dev/null 2>&1 
        done 

        echo "... checking the status for step-01: converting pod5 to fast5 (will take 1 min)"
        sleep 60
        number_of_files=$( ls $pod5_file_path | wc -l )
        number_of_files_finished=$(grep "Conversion complete" tmp/slurm/slurm.out.* | wc -l )
        while [ "$number_of_files" -ne "$number_of_files_finished" ]; do
            number_of_files_finished=$(grep "Conversion complete" tmp/slurm/slurm.out.* | wc -l )
            number_of_files_remained=$(( $number_of_files - $number_of_files_finished ))
            echo "$number_of_files_finished/$number_of_files finished, still $number_of_files_remained to be processed, ... waiting for 3 min"
        sleep 60
        done

        echo "step-01: converting pod5 to fast5: successfuly finished ------------------------"
        else 
        echo "step-01: converting pod5 to fast5: already finished ----------------------------"

    fi

###############################################################################
## step-02: basecalling

    if [ ! -d $dir_path/pod5_fast5_basecalled_guppy_cpu ] ; then
        for i in $(ls $dir_path/pod5_fast5 | head -20 ); do
            echo "step-02: basecalling: submitting sbatch for $i"
            ( sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0007_step02_demultiplexing_nanopore_basecalling_cpu.sbatch -file $i -dir_path $dir_path ) > /dev/null 2>&1 
        done

        echo "... checking the status for step-02: basecalling (will take 1 min)"
        sleep 60 
        number_of_files=$( ls $pod5_file_path | wc -l )
        number_of_files_finished=$(grep "basecalling finished" tmp/slurm/0007_basecalling.slurm.out.* | wc -l )
        while [ "$number_of_files" -ne "$number_of_files_finished" ]; do
            number_of_files_finished=$(grep "basecalling finished" tmp/slurm/0007_basecalling.slurm.out.* | wc -l )
            number_of_files_remained=$(( $number_of_files - $number_of_files_finished ))
            echo "$number_of_files_finished/$number_of_files finished for basecalling, still $number_of_files_remained to be processed, ... waiting for 3 min"
        sleep 60
        done

        else
        echo "step-02: basecalling step already finished--------------------------------------"
    fi

###############################################################################
## step-03: demultiplexing 
## @Swapnil, found 20231201 need to update below 
    # echo "running step-03: demultiplexing step -------------------------------------------"
    # if [ ! -d $dir_path/demultiplexed_guppy_cpu ] ; then
        
    #    data/pod5_fast5_basecalled_guppy_cpu
    #     (mkdir $dir_path/demultiplexed_guppy_cpu ) > /dev/null 2>&1 
    #     for i in $(ls $dir_path/pod5_fast5 ); do
    #         echo submitting sbatch for $i 
    #         ( sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0007_step03_demultiplexing_nanopore_demultiplexing_by_guppy_cpu.sbatch -file $i -dir_path $dir_path ) > /dev/null 2>&1 
    #     done

    #     ( rm tmp/slurm/0007_demultiplexing_nanopore_basecalling_by_guppy_cpu.sbatch.slurm.err.*  ) > /dev/null 2>&1 
    #     ( rm tmp/slurm/0007_demultiplexing_nanopore_basecalling_by_guppy_cpu.sbatch.slurm.out.*  ) > /dev/null 2>&1 
    #     echo "... checking the status for step-03: demultiplexing (will take 1 min)"
    #     sleep 60 
    #     number_of_files=$( ls $pod5_file_path | wc -l )
    #     number_of_files_finished=$(grep "demultiplexing finished" tmp/slurm/0007_demultiplexing_nanopore_basecalling_by_guppy_cpu.sbatch.slurm.out.* | wc -l )
    #     while [ "$number_of_files" -ne "$number_of_files_finished" ]; do
    #         number_of_files_finished=$(grep "demultiplexing finished" tmp/slurm/0007_demultiplexing_nanopore_basecalling_by_guppy_cpu.sbatch.slurm.out.* | wc -l )
    #         number_of_files_remained=$(( $number_of_files - $number_of_files_finished ))
    #         echo "$number_of_files_finished/$number_of_files finished for demultiplexing, still $number_of_files_remained to be processed, ... waiting for 3 min"
    #     sleep 60
    #     done
        
    #     echo "step-03: demultiplexing finished -----------------------------------------------"
    #     else
    #     echo "step-03: demultiplexing step already finished ----------------------------------"
    # fi

    ## get the stat of "pass"ed reads
    reads=0
    for i in $( ls data/pod5_fast5_basecalled_guppy_cpu/all_files ); do 
        echo $i
        reads=$final_passed_reads
        passed_reads=$(grep -c "TRUE" data/pod5_fast5_basecalled_guppy_cpu/all_files/$i/sequencing_summary.txt)
        final_passed_reads=$(( $reads + $passed_reads ))
        echo $final_passed_reads
    done 
    exit 
###############################################################################
## step-04: collect data coming from different files to single file 

    echo "step-04: fastq combining step: running: ---------------------------------------------"

    (mkdir results/0007_basecalling_demultiplexing_nanopore-singlex_by_guppy-cpu/fastq/ ) > /dev/null 2>&1 
    if [ ! -d results/0007_basecalling_demultiplexing_nanopore-singlex_by_guppy-cpu/fastq/$barcode.fastq ] ; then 
        for i in $(ls $dir_path/pod5_fast5 ); do
            echo $i
            barcodes=$( ls $dir_path/demultiplexed_guppy_cpu/$i | grep -v txt | grep -v log )
            for barcode in $barcodes ; do 
                cat $dir_path/demultiplexed_guppy_cpu/$i/$barcode/*.fastq >> $dir_path/demultiplexed_guppy_cpu/all/$barcode.fastq
            done
        done

        ## create stat file 
        ( rm $dir_path/demultiplexed_guppy_cpu/all/stat.txt ) > /dev/null 2>&1 
        barcodes=$( ls $dir_path/demultiplexed_guppy_cpu/$i | grep -v txt | grep -v log )
        for barcode in $barcodes ; do 
            read_count=$( cat $dir_path/demultiplexed_guppy_cpu/all/$barcode.fastq | echo $((`wc -l`/4)) )
            echo $barcode $read_count >> $dir_path/demultiplexed_guppy_cpu/all/stat.txt
        done

        else
        echo "step-04: fastq combining step: already finished ---------------------------------"
    fi 

    echo "step-04: fastq combining step: finished --------------------------------------------"

exit 
###############################################################################
## post-processing
        ## compress fastq files to save the place
        echo "basecalling finished, compressing data"
        for i in $(ls /scratch/basecalled/$file/pass/*.fastq | awk -F'/' '{print $NF}'); do
            gzip --stdout /scratch/basecalled/$file/pass/$file.fastq > /scratch/basecalled/$file/$file.fastq.gz
            rm /scratch/basecalled/$file/pass/$file.fastq
        done

        echo "basecalling finished for $file, copying back data from GPU node to working node"
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
exit