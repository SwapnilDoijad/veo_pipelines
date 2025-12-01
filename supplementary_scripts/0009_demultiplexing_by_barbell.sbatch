#!/bin/bash
#SBATCH --job-name=0009_demultiplexing_by_barbell
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu
#SBATCH --output=results/0009_demultiplexing_by_barbell/tmp/slurm/%j.out
#SBATCH --error=results/0009_demultiplexing_by_barbell/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
###############################################################################
echo "SBATCH STARTED : 0009_demultiplexing_by_barbell"
###############################################################################  
## step-01: preparation
    pipeline=0009_demultiplexing_by_barbell
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fastq_file_path=$(grep "my_fastq_path" $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC
    cpus=$SLURM_CPUS_PER_TASK

    export CARGO_HOME=/home/groups/VEO/tools/cargo 
    export RUSTUP_HOME=/home/groups/VEO/tools/rust 
    barbell="/home/groups/VEO/tools/barbell/v0.3.0/barbell/target/release/barbell"
    kit=$( grep my_kit $parameters | awk '{print $2}' )
    custom_primers=$( grep my_custom_primers $parameters | awk '{print $2}' )
    F_primer=$(grep my_F_primer $parameters | awk '{print $2}')
    R_primer=$(grep my_R_primer $parameters | awk '{print $2}')
###############################################################################
	log "STARTED: $pipeline: $kit -----------------------------" # && clean
###############################################################################
    ## if compressed fastq files, unzip them

    if [ $custom_primers == "No" ] ; then

        for i in $( cat $sublist ) ; do
            mkdir -p $raw_files/$i
            # Annotate
            $barbell kit -k $kit -i $fastq_file_path/$i.fastq -o $raw_files/$i --maximize
            
            # Trim
            $barbell trim \
                -i $raw_files/$i/filtered.tsv \
                -r "$raw_fastq" \
                -o $raw_files/trimmed
        done 

    fi
############################################################################### 
## for NON-kit based demultiplexing
    # 	F_primer_seq="/vast/groups/VEO/shared_data/angela/F_primers.txt"
    # 	R_primer_seq="/vast/groups/VEO/shared_data/angela/R_primers.txt"
    # 	filters="/vast/groups/VEO/shared_data/angela/results/0009_demultiplexing_by_barbell/tmp/filters.txt"

    # for primers in $(cat list.mut.txt ); do 
    # 	echo $primers

        # mkdir results/0009_demultiplexing_by_barbell/raw_files/${primers}

        ## create primer files
        ## Note that the primers with specific premix must be present 
        ## for e.g. mut1_* 
        ## see /vast/groups/VEO/shared_data/angela/F_primers.txt and /vast/groups/VEO/shared_data/angela/R_primers.txt
        ## this is needed for barbell to work properly
            # grep -A 1 -E "${primers}_" "$F_primer_seq" \
            # > "results/0009_demultiplexing_by_barbell/primers/${primers}_F_primers.txt"

            # grep -A 1 -E "${primers}_" "$R_primer_seq" \
            # > "results/0009_demultiplexing_by_barbell/primers/${primers}_R_primers.txt"

        ## annotate reads
            # /home/groups/VEO/tools/barbell/v0.3.0/barbell/target/release/barbell annotate \
            # -i /vast/groups/VEO/shared_data/angela/data/raw_reads.no_trim.fastq \
            # -q results/0009_demultiplexing_by_barbell/primers/${primers}_F_primers.txt,results/0009_demultiplexing_by_barbell/primers/${primers}_R_primers.txt \
            # -b Ftag,Rtag \
            # -o results/0009_demultiplexing_by_barbell/raw_files/${primers}/annotations.tsv \
            # -t 16 > results/0009_demultiplexing_by_barbell/raw_files/${primers}/log.txt 2>&1

        ## inspect patterns per read and manually create filters
        ## genereally
                            ## Single-end left Ftag
                            ## Ftag[fw, *, @left(0..250), >>]

                            ## Single-end left Rtag
                            ## Rtag[fw, *, @left(0..250), >>]

                            ## Dual-end: F on left, R on right
                            ## Ftag[fw, *, @left(0..250), >>]__Rtag[<<, rc, *, @right(0..250)]

                            ## Dual-end: R on left, F on right
                            ## Rtag[fw, *, @left(0..250), >>]__Ftag[<<, rc, *, @right(0..250)]

            # /home/groups/VEO/tools/barbell/v0.3.0/barbell/target/release/barbell  inspect \
            # -i results/0009_demultiplexing_by_barbell/raw_files/${primers}/annotations.tsv \
            # -o results/0009_demultiplexing_by_barbell/raw_files/${primers}/pattern_per_read.tsv \
            # >> results/0009_demultiplexing_by_barbell/raw_files/${primers}/log.txt 2>&1

        # $barbell filter \
        # -i results/0009_demultiplexing_by_barbell/raw_files/${primers}/annotations.tsv \
        # -f $filters \
        # -o results/0009_demultiplexing_by_barbell/raw_files/${primers}/filtered.txt \
        # > results/0009_demultiplexing_by_barbell/raw_files/${primers}/log.txt 2>&1

    # 	/home/groups/VEO/tools/barbell/v0.3.0/barbell/target/release/barbell trim \
    # 	-i results/0009_demultiplexing_by_barbell/raw_files/${primers}/filtered.txt \
    # 	-r data/raw_reads.no_trim.fastq \
    # 	--no-orientation --only-side left \
    # 	-o results/0009_demultiplexing_by_barbell/fastq \
    # 	>> results/0009_demultiplexing_by_barbell/raw_files/${primers}/log.txt 2>&1
    # done 


###############################################################################
## just trimp adapters. 
    # barbell annotate -q adapters.fasta -b Fflank -i reads.fastq -o anno.tsv -t 10
    # barbell filter -i anno.tsv -o filtered.tsv
    # barbell trim -i filtered.tsv -r reads.fastq -o trimmed

###############################################################################
	log "FINISHED: $pipeline -----------------------------" # && clean
###############################################################################