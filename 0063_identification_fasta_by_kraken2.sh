###############################################################################
## header
    start_time=$(date +"%Y%m%d_%H%M%S")
###############################################################################
## output
    # 1 Percentage of fragments covered by the clade rooted at this taxon
    # 2 Number of fragments covered by the clade rooted at this taxon
    # 3 Number of fragments assigned directly to this taxon
    # 4 A rank code, indicating (U)nclassified, (R)oot, (D)omain, (K)ingdom, (P)hylum, (C)lass, (O)rder, (F)amily, (G)enus, or (S)pecies. Taxa that are not at any of these 10 ranks have a rank code that is formed by using the rank code of the closest ancestor rank with a number indicating the distance from that rank. E.g., "G2" is a rank code indicating a taxon is between genus and species and the grandparent taxon is at the genus rank.
    # 5 NCBI taxonomic ID number
    # 6 Indented scientific name
###############################################################################
## installation 
    #  /home/groups/VEO/tools/kraken2/v2.1.2-build
    #  /home/groups/VEO/tools/kraken2/v2.1.2-inspect
###############################################################################
## step-01: preparations

    if [ -f list.my_fasta.txt ]; then 
        list=list.my_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep fasta result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi

    (mkdir -p results/0063_identification_fasta_by_kraken2/raw_files ) > /dev/null 2>&1
    (mkdir -p results/0063_identification_fasta_by_kraken2/tmp/lists ) > /dev/null 2>&1
    (mkdir -p results/0063_identification_fasta_by_kraken2/tmp/sbatch ) > /dev/null 2>&1
    (mkdir -p results/0063_identification_fasta_by_kraken2/tmp/slurm ) > /dev/null 2>&1

    ( rm results/0063_identification_fasta_by_kraken2/tmp/lists/*.* ) > /dev/null 2>&1
    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 1 ))
    split -l "$lines_per_part" -a 3 -d "$list" list.0063_identification_fasta_by_kraken2_
    mv list.0063_identification_fasta_by_kraken2_* results/0063_identification_fasta_by_kraken2/tmp/lists/
###############################################################################
## step-02: create sbatch and run 

    for sublist in $( ls results/0063_identification_fasta_by_kraken2/tmp/lists/ ) ; do
        echo $sublist
        sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0063_identification_fasta_by_kraken2.sbatch | sed "s#XYZ#$fasta_file_path#g" \
        > results/0063_identification_fasta_by_kraken2/tmp/sbatch/0063_identification_fasta_by_kraken2.$sublist.sbatch
        sbatch results/0063_identification_fasta_by_kraken2/tmp/sbatch/0063_identification_fasta_by_kraken2.$sublist.sbatch
    done 

    total_number_of_files_to_process=$( ls results/0063_identification_fasta_by_kraken2/tmp/lists/ | wc -l  )

###############################################################################
## step-03: wait untill assembly is finished
	if [ ! -f results/0053_metagenome_assembly_by_raven/tmp/get_the_stat_of_fasta_finished.txt ] ; then 
		counter=0
		max_attempts=180  # 60 attempts * 1 minute = 1 hour

		cat $list > results/0053_metagenome_assembly_by_raven/tmp/tmp.list

		while [ $counter -lt $max_attempts ]  && [ -s results/0053_metagenome_assembly_by_raven/tmp/tmp.list ] ; do
			for F1 in $(cat results/0053_metagenome_assembly_by_raven/tmp/tmp.list); do
				if [ -f "results/0053_metagenome_assembly_by_raven/raw_files/$F1/$F1.fasta" ]; then
					sed -i "/$F1/d" results/0053_metagenome_assembly_by_raven/tmp/tmp.list
					echo "raven assembly $F1 finished, no more waiting"
					break
					else
					echo "raven assembly $F1 not finished in $counter minutes"
					echo "waiting for 1 more minute and will check again (will wait maximum $max_attempts minutes)"
					sleep 60
					counter=$((counter + 1))
				fi
			done
		done

		if [ $counter -eq $max_attempts ]; then
			echo "File not found after 3 hour. Exiting..."
		fi

		rm results/0053_metagenome_assembly_by_raven/tmp/tmp.list
		sleep 60 ## needed for the files to be writen, it takes time for the raven 
		echo "raven assembly finished" > results/0053_metagenome_assembly_by_raven/tmp/raven_assembly.finished
	fi 

###############################################################################
## footer
    end_time=$(date +"%Y%m%d_%H%M%S")
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/time_calculations.sh "$start_time" "$end_time"
###############################################################################