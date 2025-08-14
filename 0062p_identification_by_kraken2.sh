#!/bin/bash
###############################################################################
    pipeline=0062_identification_by_kraken2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
	database=/veodata/03/databases/kraken2/v20250204
	source /home/groups/VEO/tools/biopython/myenv/bin/activate
    levels="P C O F G S S1"
	# domains="Bacteria Archaea Eukaryota Viruses Viroids Other_sequences Environmental_samples Unclassified Unclassified_sequences"
	domains="Bacteria Archaea Eukaryota Viruses"
###############################################################################
    log "STARTED: $pipeline"
###############################################################################
	for F1 in $(cat list.$pipeline.txt ); do
		( mkdir -p $raw_files/$F1/split_reports ) > /dev/null 2>&1

		python3 $suppl_scripts/$pipeline.split.py \
		-i $raw_files/$F1/report.txt \
		-o $raw_files/$F1/split_reports \

		head -3 $raw_files/$F1/report.txt > $raw_files/$F1/report.tmp

		for domain in $domains; do
			if [ -f $raw_files/$F1/split_reports/${domain}_report.txt ]; then
				mkdir -p $raw_files/$F1/bracken/$domain

				cat $raw_files/$F1/report.tmp $raw_files/$F1/split_reports/${domain}_report.txt \
				> $raw_files/$F1/split_reports/${domain}_report.2.txt 
				mv $raw_files/$F1/split_reports/${domain}_report.2.txt $raw_files/$F1/split_reports/${domain}_report.txt

				for level in $levels; do
					log "running bracken for $F1 : $domain : $level"

					( $tools/bracken/v3.1/Bracken/bracken \
					-d $database \
					-i $raw_files/$F1/split_reports/${domain}_report.txt \
					-o $raw_files/$F1/bracken/$domain/$level.bracken \
					-l $level ) > /dev/null 2>&1

					mkdir -p $wd/combined/$domain/$level > /dev/null 2>&1
					awk -F'\t' '{OFS="\t"; if ($7 != 0) print $1, $7}' $raw_files/$F1/bracken/$domain/$level.bracken \
					| tr ' ' '_' > $wd/combined/$domain/$level/$F1.$level.bracken

				done
				
			fi 
		done 
		rm -rf $raw_files/$F1/report.tmp  > /dev/null 2>&1
	done 
###############################################################################
	for domain in $domains; do
		for level in $levels; do
			rm $wd/combined/$domain/$level/*.tsv > /dev/null 2>&1
			rm $wd/combined/$domain/$level/*.png > /dev/null 2>&1

			log "creating matrix and plot : $domain : $level"

			python $suppl_scripts/$pipeline.matrix.py \
			-i $wd/combined/$domain/$level \
			-o $wd/combined/$domain/$level/$level.tsv

			python $suppl_scripts/$pipeline.plot.py \
			-i $wd/combined/$domain/$level/$level.tsv \
			-o $wd/combined/$domain/$level/$level.png
		done
	done

###############################################################################
	## calculate root fractions

	mkdir -p $wd/combined/root > /dev/null 2>&1
	for F1 in $(cat list.$pipeline.txt ); do
		
		# for Unclassified
		head -1 $raw_files/$F1/report.txt \
		> $raw_files/$F1/domain.tmp

		for domain in $domains; do
			sed -n '4p' $raw_files/$F1/split_reports/${domain}_report.txt \
			>> $raw_files/$F1/domain.tmp
		done

		echo -e "name\tfraction_total_reads" > $wd/combined/root/$F1.tsv

		awk '{print $6, $1}' $raw_files/$F1/domain.tmp \
		| tr ' ' '\t' >> $wd/combined/root/$F1.tsv

		rm -rf $raw_files/$F1/domain.tmp > /dev/null 2>&1
	done

		rm -rf $wd/combined/root/matrix.tsv > /dev/null 2>&1
		rm -rf $wd/combined/root/matrix.png > /dev/null 2>&1

		python $suppl_scripts/$pipeline.matrix.py \
		-i $wd/combined/root \
		-o $wd/combined/root/matrix.tsv

		python $suppl_scripts/$pipeline.plot.py \
		-i $wd/combined/root/matrix.tsv \
		-o $wd/combined/root/matrix.png

###############################################################################
	log "FINISHED: $pipeline"
###############################################################################
	# domains = {
	# 	"Unclassified": "0",              # Kraken 'U' reads
	# 	"Bacteria": "2",                  # Bacteria
	# 	"Archaea": "2157",                 # Archaea
	# 	"Eukaryota": "2759",               # Eukaryotes
	# 	"Viruses": "10239",                # Viruses
	# 	"Viroids": "12884",                # Viroids (RNA pathogens)
	# 	"Other sequences": "12908",        # Synthetic constructs, etc.
	# 	"Environmental samples": "256318", # Environmental samples node
	# 	"Unclassified sequences": "28384"  # Special NCBI bin for unclassified seqs
	# }
###############################################################################