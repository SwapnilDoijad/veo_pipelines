#!/bin/bash
###############################################################################
#SBATCH --job-name=0062_identification_by_kraken2
#SBATCH --partition=standard
#SBATCH --output=results/0062_identification_by_kraken2/tmp/slurm/%j.out
#SBATCH --error=results/0062_identification_by_kraken2/tmp/slurm/%j.err
#SBATCH --cpus-per-task=25
#SBATCH --mem=100G
###############################################################################
pipeline=0062_identification_by_kraken2
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
data_dir=$(grep "my_data_dir" $parameters | awk -F'\t' '{print $2}')
input_file_type=$( grep "my_input_file_type" $parameters | awk -F'\t' '{print $2}')
database=/veodata/03/databases/kraken2/v20250204
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

            ( $tools/kraken2/v2.1.2/kraken2 \
            --db $database \
            --threads $SLURM_CPUS_PER_TASK \
            --report $raw_files/$F1/report.txt \
            --use-names $data_dir/$F1.fasta ) > /dev/null 2>&1 

        done
        
        elif [ "$input_file_type" == "r" ] ; then

            for F1 in $(cat $sublist ); do
                if [ ! -f $raw_files/$F1/report.txt ]; then
                    log "running kraken2 (raw_reads) for $F1"
                    ( mkdir -p $raw_files/$F1/split_reports ) > /dev/null 2>&1

                    ( $tools/kraken2/v2.1.2/kraken2 \
                    --db $database \
                    --threads $SLURM_CPUS_PER_TASK \
                    --report $raw_files/$F1/report.txt \
                    --use-names \
                    --paired $data_dir/"$F1"_R1.fastq.gz $data_dir/"$F1"_R2.fastq.gz ) > /dev/null 2>&1

                    python $suppl_scripts/$pipeline.split.py \
                    -i $raw_files/$F1/report.txt \
                    -o $raw_files/$F1/split_reports \

                fi

                head -3 $raw_files/$F1/report.txt > $raw_files/$F1/report.tmp
                for domain in $(basename -a $raw_files/$F1/split_reports/*_report.txt | sed 's/_report.txt//g'); do
                    cat $raw_files/$F1/report.tmp $raw_files/$F1/split_reports/${domain}_report.txt \
                    > $raw_files/$F1/split_reports/${domain}_report.2.txt 
                    mv $raw_files/$F1/split_reports/${domain}_report.2.txt $raw_files/$F1/split_reports/${domain}_report.txt

                    for level in $levels; do
                        log "running bracken for $F1 at level $level"
                        mkdir -p $raw_files/$F1/bracken/$domain/$level

                        $tools/bracken/v3.1/Bracken/bracken \
                        -d $database \
                        -i $raw_files/$F1/split_reports/${domain}_report.txt \
                        -o $raw_files/$F1/bracken/$domain/$level.bracken \
                        -l $level
                    done

                done 
                
                head -1 $raw_files/$F1/split_reports/*.txt \
                | grep -v '^==>' | sed '/^$/d' \
                > $raw_files/$F1/domain.tsv
            done

        A1=$(awk -F'\t' ' $4=="S" {print $0}' $raw_files/$F1/report.txt | head -1 | sed 's/                  //g' | sed 's/ /_/g' )
        echo -e "$F1\t$A1" >> $wd/report.csv

    fi

###############################################################################
    log "FINISHED: $pipeline : $sublist" && clean
###############################################################################
## post-processing
	# database=/veodata/03/databases/kraken2/v20250204
	# pipeline=0062_identification_by_kraken2
	# source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

	# source /home/groups/VEO/tools/biopython/myenv/bin/activate
    # levels="P C O F G S S1"

    # for level in $levels; do
    #     mkdir -p $raw_files/bracken/$level
	# 	for F1 in $(cat list.0062_identification_by_kraken2.txt ); do
	# 		awk -F'\t' '{OFS="\t"; if ($7 != 0) print $1, $7}' $raw_files/$F1/bracken/$level.bracken \
	# 		| tr ' ' '_' > $raw_files/bracken/$level/$F1.$level.bracken
	# 	done

	# 		$tools/bracken/v3.1/Bracken/bracken \
	# 		-d $database \
	# 		-i $raw_files/$F1/report.txt \
	# 		-o $raw_files/$F1/bracken/$level.bracken \
	# 		-l $level

	# 	python $suppl_scripts/0062_identification_by_kraken2.matrix.py \
	# 	-i $raw_files/bracken/$level \
	# 	-o $raw_files/bracken/$level/$level.tsv

	# 	python $suppl_scripts/0062_identification_by_kraken2.plot.py \
	# 	-i $raw_files/bracken/$level/$level.tsv \
	# 	-o $raw_files/bracken/$level/$level.png
    # done
###############################################################################
    #( kraken2 --db $database --threads 8 --unclassified-out $raw_files/$F1/"unclassified#".fastq --classified-out $raw_files/$F1/"$F1"_"classified#".fastq --report $raw_files/$F1/report.txt --use-names --output $raw_files/$F1/results.txt --paired $path/data/illumina/final_reads/"$F1"_*R1*.gz $path/data/illumina/final_reads/"$F1"_*R2*.gz ) > /dev/null 2>&1 
    #gzip -c $raw_files/$F1/"unclassified#".fastq > $raw_files/$F1/"unclassified#".fastq.gz
    #gzip -c $raw_files/$F1/"classified#".fastq > $raw_files/$F1/"classified#".fastq.gz
###############################################################################