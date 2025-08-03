#!/bin/bash
#SBATCH --job-name=0054_metagenome_assembly_by_metaspades_for_illumina
#SBATCH --partition=fat,gpu-veo,gpu-test,gpu
#SBATCH --output=results/0054_metagenome_assembly_by_metaspades_for_illumina/tmp/slurm/%j.out
#SBATCH --error=results/0054_metagenome_assembly_by_metaspades_for_illumina/tmp/slurm/%j.err
#SBATCH --mem=700G
#SBATCH --cpus-per-task=20
###############################################################################
## header
    pipeline=0054_metagenome_assembly_by_metaspades_for_illumina
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    data_type=$( grep -w "my_data_type" $parameters | awk '{print $2}' )
	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    log "SBATCH STARTED : $pipeline -----------------------------------"

    log "data_type = $data_type"
    log "fastq_path = $fastq_path"
###############################################################################
## step-01: preparatoion

    for i in $(cat $sublist); do
        mkdir $raw_files/$i > /dev/null 2>&1

        if [ $data_type = "paired" ] ; then 
            if [ ! -f $raw_files/$i/contigs.fasta ] || grep -q "== Error ==" $raw_files/$i/spades.log ; then 
                log "STARTED : metaspades-assembler for $i : $read_type"

                python3 /home/groups/VEO/tools/SPAdes/v3.15.5/metaspades.py \
                -1 $fastq_path/$i*R1*.fastq.gz \
                -2 $fastq_path/$i*R2*.fastq.gz \
                -t $SLURM_CPUS_PER_TASK \
                -m 500 \
                -o $raw_files/$i \
                & my_pid=$!
                get_resource_stat $my_pid $wd/tmp/resource_log/$i.metaspades.paired.tsv

                log "FINISHED : metaspades-assembler for $i : $read_type"
                else
                log "ALREADY FINISHED : metaspades-assembler for $i : $read_type"
            fi
        elif [ $data_type = "single" ] ; then 
            if [ ! -f $raw_files/$i/contigs.fasta ] ; then 
                log "STARTED : metaspades-assembler for $i : $read_type"

                python3 /home/groups/VEO/tools/SPAdes/v3.15.5/metaspades.py \
                -s $fastq_path/$i.fastq.gz \
                -t $SLURM_CPUS_PER_TASK \
                -m 500 \
                -o $raw_files/$i \
                & my_pid=$!
                get_resource_stat $my_pid $wd/tmp/resource_log/$i.metaspades.single.tsv

                log "FINISHED : metaspades-assembler for $i : $read_type"
                else
                log "ALREADY FINISHED : metaspades-assembler for $i : $read_type"
            fi 
        fi
    done

    mkdir $raw_files/all_fasta > /dev/null 2>&1
    for i in $(cat $sublist); do
        if [ -f $raw_files/$i/contigs.fasta ] && [ ! -f $wd/all_fasta/$i.contigs.fasta ] ; then
            cp $raw_files/$i/contigs.fasta $wd/all_fasta/$i.fasta

            number_of_contigs=$(grep -c ">" $raw_files/$i/contigs.fasta)
            echo $number_of_contigs >> summary.tsv
            else 
            echo "$i NA" >> summary.tsv
        fi
    done

###############################################################################
## step-02: run quast

        for i in $(cat $sublist); do
            if [ -f $raw_files/$i/contigs.fasta ] ; then 
                if [ ! -f $raw_files/$i/quast/report.html ] ; then 
				    log "STARTED : $pipeline for $i : quast"

                    mkdir -p $raw_files/$i/quast
                
                    python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
                    -o $raw_files/$i/quast/ \
                    -t 40 \
                    --silent \
                    $raw_files/$i/contigs.fasta \
                    & my_pid=$!
                    get_resource_stat $my_pid $wd/tmp/resource_log/$i.quast.tsv

                    log "FINISHED : $pipeline for $i : quast"
                    else
                    log "ALREADY FINISHED : $pipeline for $i : quast"
                fi
                else
                log "ERROR : $pipeline for $i : contigs.fasta not found"
            fi 
        done
###############################################################################
## step-03: run metaquast

    for i in $(cat $sublist); do  
		if [ -f $raw_files/$i/contigs.fasta ] ; then 
			if [ ! -f $raw_files/$i/metaquast/report.html ] ; then 
                log "STARTED : $pipeline for $i : metaquast"

				mkdir -p $raw_files/$i/metaquast/fasta

				python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent \
                -t 40 \
				-o $raw_files/$i/metaquast/ \
				$raw_files/$i/contigs.fasta \
                & my_pid=$!
                get_resource_stat $my_pid $wd/tmp/resource_log/$i.metaquast.tsv

                log "FINISHED : $pipeline for $i : metaquast"
                else
                log "ALREADY FINISHED : $pipeline for $i : metaquast"
			fi
            log "ERROR : $pipeline for $i : contigs.fasta not found"
		fi
    done 

###############################################################################
## footer
    log "SBATCH ENDED : $pipeline ----------------------" && clean
###############################################################################
## manual post-processing 
    # python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
    # -t 40 \
    # -o $wd/quast \
    # --silent $wd/all_fasta/*.fasta
###############################################################################
