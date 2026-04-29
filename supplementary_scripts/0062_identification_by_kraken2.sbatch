#!/bin/bash
###############################################################################
#SBATCH --job-name=0062_identification_by_kraken2
#SBATCH --partition=gpu-veo,fat,gpu-test,gpu
#SBATCH --output=results/0062_identification_by_kraken2/tmp/slurm/%j.out
#SBATCH --error=results/0062_identification_by_kraken2/tmp/slurm/%j.err
#SBATCH --cpus-per-task=25
#SBATCH --mem=200G
###############################################################################
pipeline=0062_identification_by_kraken2
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
data_dir=$(grep "my_data_dir" $parameters | awk -F'\t' '{print $2}')
input_file_type=$( grep "my_input_file_type" $parameters | awk -F'\t' '{print $2}')
database=$(grep "my_database" $parameters | awk -F'\t' '{print $2}')
levels="P C O F G S S1"
source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate perl_v5.32.1
###############################################################################
log "STARTED: $pipeline : $sublist"
###############################################################################
log "data_dir: $data_dir"
log "input_file_type: $input_file_type"
log "database: $database"
###############################################################################
## run kraken2
    if [  "$input_file_type" == "f" ] ; then 
        for F1 in $(cat $sublist ); do
            log "running kraken2 (fasta) for $F1"
            ( mkdir $raw_files/$F1 ) > /dev/null 2>&1  

            ( /usr/bin/perl $tools/kraken2/v2.1.2/kraken2 \
            --db $database \
            --threads $SLURM_CPUS_PER_TASK \
            --report $raw_files/$F1/report.txt \
            --use-names $data_dir/$F1.fasta ) > /dev/null 2>&1 

            python3 $suppl_scripts/$pipeline.summarise.py \
            -i $raw_files/$F1/report.txt \
            -o $raw_files/$F1/report.sp.tsv \
            -r S \
            -n 3

        done
        
        elif [ "$input_file_type" == "r" ] ; then

            for F1 in $(cat $sublist ); do
                if [ ! -f $raw_files/$F1/report.txt ]; then
                    log "running kraken2 (raw_reads) for $F1"
                    ( mkdir $raw_files/$F1 ) > /dev/null 2>&1  

                    $tools/kraken2/v2.1.2/kraken2 \
                    --db $database \
                    --threads $SLURM_CPUS_PER_TASK \
                    --report $raw_files/$F1/report.txt \
                    --use-names \
                    --paired $data_dir/"$F1"_R1.fastq.gz $data_dir/"$F1"_R2.fastq.gz #) > /dev/null 2>&1

                fi

            done

        elif [ "$input_file_type" == "n" ] ; then
            echo -e "IDs\ttotal_reads\tmicrobe_reads\teukaryote_reads" > $wd/report.nanopore.tsv

            for F1 in $(cat $sublist ); do
                if [ ! -f $raw_files/$F1/report.txt ]; then
                    log "running kraken2 (nanopore raw_reads) for $F1"
                    ( mkdir $raw_files/$F1 ) > /dev/null 2>&1  

                        # --confidence 0.1          reduces false positives from ONT errors
                        # --minimum-hit-groups 3    stronger evidence required              
                        # --classified-out          reads assigned to taxa                  
                        # --unclassified-out        useful microbial leftovers / unknowns   
                        # --use-names               readable output                         

                    $tools/kraken2/v2.1.2/kraken2 \
                    --db $database \
                    --threads $SLURM_CPUS_PER_TASK \
                    --use-names \
                    --gzip-compressed \
                    --confidence 0.1 \
                    --minimum-hit-groups 3 \
                    --report $raw_files/$F1/"$F1".report.txt \
                    --output $raw_files/$F1/"$F1".out.txt \
                    --classified-out $raw_files/$F1/"$F1"_"classified".fastq.gz \
                    --unclassified-out $raw_files/$F1/"$F1"_"unclassified".fastq.gz \
                    $data_dir/"$F1".fastq.gz


                        # -t 2759 = removing taxids Eukaryota + descendants
                    python3 /home/groups/VEO/tools/krakentools/v1.2/KrakenTools/extract_kraken_reads.py \
                    -k $raw_files/$F1/"$F1".out.txt \
                    -s $data_dir/"$F1".fastq.gz \
                    -o $raw_files/$F1/"$F1"_microbes.fastq \
                    -t 2759 \
                    -r $raw_files/$F1/"$F1".report.txt \
                    --include-children \
                    --exclude \
                    --fastq-output

                    gzip $raw_files/$F1/"$F1"_microbes.fastq

                    total_reads=$(count_reads_from_fastq $data_dir/"$F1".fastq.gz)
                    microbe_reads=$( count_reads_from_fastq $raw_files/$F1/"$F1"_microbes.fastq.gz )
                    eukaryote_reads=$(( total_reads - microbe_reads ))
                    echo -e "$F1\t$total_reads\t$microbe_reads\t$eukaryote_reads" >> $wd/report.nanopore.tsv
                fi

            done

        A1=$(awk -F'\t' ' $4=="S" {print $0}' $raw_files/$F1/report.txt | head -1 | sed 's/                  //g' | sed 's/ /_/g' )
        echo -e "$F1\t$A1" >> $wd/report.csv

    fi

###############################################################################
    log "FINISHED: $pipeline : $sublist" && clean
###############################################################################
    #( kraken2 --db $database --threads 8 --unclassified-out $raw_files/$F1/"unclassified#".fastq --classified-out $raw_files/$F1/"$F1"_"classified#".fastq --report $raw_files/$F1/report.txt --use-names --output $raw_files/$F1/results.txt --paired $path/data/illumina/final_reads/"$F1"_*R1*.gz $path/data/illumina/final_reads/"$F1"_*R2*.gz ) > /dev/null 2>&1 
    #gzip -c $raw_files/$F1/"unclassified#".fastq > $raw_files/$F1/"unclassified#".fastq.gz
    #gzip -c $raw_files/$F1/"classified#".fastq > $raw_files/$F1/"classified#".fastq.gz
###############################################################################