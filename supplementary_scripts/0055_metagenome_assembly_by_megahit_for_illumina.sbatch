#!/bin/bash
#SBATCH --job-name=0055_metagenome_assembly_by_megahit_for_illumina
#SBATCH --partition=fat,gpu-veo,gpu-test,gpu
#SBATCH --output=results/0055_metagenome_assembly_by_megahit_for_illumina/tmp/slurm/%j.out
#SBATCH --error=results/0055_metagenome_assembly_by_megahit_for_illumina/tmp/slurm/%j.err
#SBATCH --mem=230G
#SBATCH --cpus-per-task=20
###############################################################################
## header
    pipeline=0055_metagenome_assembly_by_megahit_for_illumina
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    data_type=$( grep -w "my_data_type" $parameters | awk '{print $2}' )
	fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )
    sublist=$wd/tmp/lists/ABC

    log "SBATCH STARTED : $pipeline : $sublist -----------------------------------"
    log "data_type = $data_type"
    log "fastq_path = $fastq_path"
###############################################################################
## step-01: run megahit
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate megahit_v1.2.9
###############################################################################
    for i in $(cat $sublist); do
        if [ $data_type = "paired" ] && [ ! -f $raw_files/$i/$i.contigs.fa ] ; then 
            log "STARTED : $pipeline for $i"

            megahit \
            -1 $fastq_path/$i*R1*.fastq.gz \
            -2 $fastq_path/$i*R2*.fastq.gz \
            -t $SLURM_CPUS_PER_TASK \
            -m 0.9 \
            --out-prefix $i \
            --min-contig-len 500 \
            -o $raw_files/$i \
            & my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.paired.tsv 

            log "FINISHED : $pipeline for $i"
            else
            log "ALREADY FINISHED : $pipeline for $i"
        fi


        if [ "$data_type" = "single" ] && [ ! -f $raw_files/$i/$i.contigs.fa ]  ; then
            log "STARTED : $pipeline : $data_type : for $i"

            megahit \
            -r $fastq_path/$i.fastq.gz \
            -t $SLURM_CPUS_PER_TASK \
            -m 0.9 \
            --out-prefix $i \
            --min-contig-len 500 \
            -o $raw_files/$i \
            & my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.single.tsv

            log "FINISHED : $pipeline : $data_type : for $i"
            else
            log "ALREADY FINISHED : $pipeline : $data_type : for $i"
        fi

        cp $raw_files/$i/$i.contigs.fa $wd/all_fasta/$i.fasta
    done


    mkdir $wd/all_fasta > /dev/null 2>&1
    for i in $(cat $sublist); do
        if [ -f $wd/all_fasta/$i.fasta ] ; then
            number_of_contigs=$( grep -c ">" $wd/all_fasta/$i.fasta )
            echo -e "$i\t$number_of_contigs" >> $wd/summary.tsv
            else 
            echo -e "$i\tNA" >> $wd/summary.tsv
        fi
    done

###############################################################################
## step-02: run quast

        for i in $(cat $sublist); do
            if [ -f $wd/all_fasta/$i.fasta ] ; then 
                if [ ! -f $raw_files/$i/quast/report.html ] ; then 
				    log "STARTED : $pipeline for $i : quast"

                    mkdir -p $raw_files/$i/quast
                
                    python3 /home/groups/VEO/tools/quast/v5.2.0/quast.py \
                    -o $raw_files/$i/quast/ \
                    --silent \
                    $wd/all_fasta/$i.fasta \
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
		if [ -f $wd/all_fasta/$i.fasta ] ; then 
			if [ ! -f $raw_files/$i/metaquast/report.html ] ; then 
				log "metaquast for $i: running"

				mkdir -p $raw_files/$i/metaquast/fasta

				python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent \
				-o $raw_files/$i/quast/ \
				$wd/all_fasta/$i.fasta \
                & my_pid=$!
                get_resource_stat $my_pid $wd/tmp/resource_log/$i.metaquast.tsv

				else
				log "metaquast for $i: already finished"
			fi
		fi
    done 
###############################################################################
## footer
    log "SBATCH ENDED : $pipeline ----------------------" && clean
###############################################################################

