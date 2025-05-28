#!/bin/bash
###############################################################################
#SBATCH --job-name=0062_identification_by_kraken2
#SBATCH --partition=standard
#SBATCH --output=results/0062_identification_by_kraken2/tmp/slurm/%j.out
#SBATCH --error=results/0062_identification_by_kraken2/tmp/slurm/%j.err
#SBATCH --cpus-per-task=25
###############################################################################
pipeline=0062_identification_by_kraken2
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
data_dir=$(grep "my_data_dir" $parameters | awk -F'\t' '{print $2}')
input_file_type=$( grep "my_input_file_type" $parameters | awk -F'\t' '{print $2}')
###############################################################################
log "STARTED: $pipeline : $sublist"
log "data_dir: $data_dir"
log "input_file_type: $input_file_type"
###############################################################################
## run kraken2
    if [  "$input_file_type" == "f" ] ; then 
        for F1 in $(cat $sublist ); do

            log "running kraken2 (fasta) for $F1"
            ( mkdir $raw_files/$F1 ) > /dev/null 2>&1  

            ( /home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
            --db /veodata/03/databases/kraken2/v20180901 \
            --threads 20 \
            --report $raw_files/$F1/report.txt \
            --use-names $data_dir/$F1.fasta ) > /dev/null 2>&1 

            #( kraken2 --db /veodata/03/databases/kraken2/v20180901 --threads 8 --unclassified-out $raw_files/$F1/unclassified.txt  --classified-out $raw_files/$F1/classified.txt --report $raw_files/$F1/report.txt --use-names --output $raw_files/$F1/results.txt results/0040_assembly/all_fasta/$F1.fasta ) > /dev/null 2>&1 
            #gzip -c $raw_files/$F1/"unclassified#".fastq > $raw_files/$F1/"unclassified#".fastq.gz
            #gzip -c $raw_files/$F1/"classified#".fastq > $raw_files/$F1/"classified#".fastq.gz
            
            A1=$(awk -F'\t' ' $4=="S" {print $0}' $raw_files/$F1/report.txt | head -1 | sed 's/                  //g' | sed 's/ /_/g' )
            echo -e "$F1\t$A1" >> $wd/report.csv
        done
        
        elif [ "$input_file_type" == "r" ] ; then
        for F1 in $(cat $sublist ); do
            log "running kraken2 (raw_reads) for $F1"
            ( mkdir $raw_files/$F1 ) > /dev/null 2>&1 

            ( /home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
            --db /veodata/03/databases/kraken2/v20180901 \
            --threads 20 \
            --report $raw_files/$F1/report.txt \
            --use-names \
            --paired $data_dir/"$F1"_*R1*.gz $data_dir/"$F1"_*R2*.gz ) > /dev/null 2>&1

            #( kraken2 --db /veodata/03/databases/kraken2/v20180901 --threads 8 --unclassified-out $raw_files/$F1/"unclassified#".fastq --classified-out $raw_files/$F1/"$F1"_"classified#".fastq --report $raw_files/$F1/report.txt --use-names --output $raw_files/$F1/results.txt --paired $path/data/illumina/final_reads/"$F1"_*R1*.gz $path/data/illumina/final_reads/"$F1"_*R2*.gz ) > /dev/null 2>&1 
            #gzip -c $raw_files/$F1/"unclassified#".fastq > $raw_files/$F1/"unclassified#".fastq.gz
            #gzip -c $raw_files/$F1/"classified#".fastq > $raw_files/$F1/"classified#".fastq.gz
            A1=$(awk -F'\t' ' $4=="S" {print $0}' $raw_files/$F1/report.txt | head -1 | sed 's/                  //g' | sed 's/ /_/g' )
            echo -e "$F1\t$A1" >> $wd/report.csv
        done
        
        elif [  "$input_file_type" == "s" ] ; then
        for F1 in $(cat $sublist ); do
            log "running kraken2 (filtered_reads) for $F1"
            ( mkdir $raw_files/$F1 ) > /dev/null 2>&1 
            
            ( /home/groups/VEO/tools/kraken2/v2.1.2/kraken2 \
            --db /veodata/03/databases/kraken2/v20180901 \
            --threads 20 \
            --report $raw_files/$F1/report.txt \
            --use-names \
            --paired $data_dir/"$F1"_R1_001.filtered_paired.fastq.gz \
            $data_dir/"$F1"_R2_001.filtered_paired.fastq.gz ) > /dev/null 2>&1 

            #( kraken2 --db /veodata/03/databases/kraken2/v20180901 --threads 8 --unclassified-out $raw_files/$F1/"unclassified#".fastq  --classified-out $raw_files/$F1/"$F1"_"classified#".fastq --report $raw_files/$F1/report.txt --use-names --output $raw_files/$F1/results.txt --paired $data_dir/"$F1"_R1_001.filtered_paired.fastq.gz $data_dir/"$F1"_R2_001.filtered_paired.fastq.gz ) > /dev/null 2>&1 
            #gzip -c $raw_files/$F1/"unclassified#".fastq > $raw_files/$F1/"unclassified#".fastq.gz
            #gzip -c $raw_files/$F1/"classified#".fastq > $raw_files/$F1/"classified#".fastq.gz
            A1=$(awk -F'\t' ' $4=="S" {print $0}' $raw_files/$F1/report.txt | head -1 | sed 's/                  //g' | sed 's/ /_/g' )
            echo -e "$F1\t$A1" >> $wd/report.csv
        done
    fi
###############################################################################
    log "FINISHED: $pipeline : $sublist"
###############################################################################