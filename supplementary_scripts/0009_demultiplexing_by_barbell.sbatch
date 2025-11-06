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
    barbell="/home/groups/VEO/tools/barbell/v0.1.9/barbell/target/release/barbell"
    kit=$( grep my_kit $parameters | awk '{print $2}' )
###############################################################################
	log "STARTED: $pipeline -----------------------------" # && clean
###############################################################################

    for i in $( cat $sublist ) ; do
        mkdir -p $raw_files/$i
        # Annotate
        $barbell kit \
            -k $kit \
            -i $fastq_file_path/$i.fastq \
            -o $raw_files/$i \
            --maximize

        $barbell annotate \
            -k $kit \
            -i $fastq_file_path/$i.fastq \
            -q "$fwd_primers","$rev_primers" \
            -o $raw_files/$i/annotations.txt \
            -t 8 \
            --tune
        
        # Inspect
        $barbell inspect \
            -i $raw_files/$i/annotations.txt
        
        # Filter
        $barbell filter \
            -i $raw_files/$i/annotations.txt \
            -o $raw_files/$i/filtered.txt \
            -f .../rapid_filters.txt
        
        # Trim
        $barbell trimm \
            -i $raw_files/$i/filtered.txt \
            -r "$raw_fastq" \
            -o $out_dir/trimmed
    done 
############################################################################### 
	log "FINISHED: $pipeline -----------------------------" # && clean
###############################################################################

