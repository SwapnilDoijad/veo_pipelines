#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : 0225_gene_detection_plasmidFinder_by_blast ---------------------------------"
###############################################################################
## step-00: database creation
	# if [ ! -f /work/groups/VEO/databases/plasmidfinder/v20170202/plasmid.fasta.phr ] ; then
	# 	echo "creating blast database"
	# 	/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
	# 	-in /work/groups/VEO/databases/plasmidfinder/v20170220/plasmid.fasta \
	# 	-parse_seqids -dbtype nucl
	# fi
###############################################################################
## step-01: file and directory preparation

    pipeline=0225_gene_detection_plasmidFinder_by_blast
    wd=results/$pipeline
	makeblastdb=/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline
exit
###############################################################################

###############################################################################
## step-03 calcualte Abr-gene frequency

	echo "summarising virulence gene blast analysis"

	awk 'FNR>1' $wd/all_results/*.VFDB-blast.csv > $wd/all.VFDB-blast.tab
	ex -sc '1i|sseqid	qseqid	sstart	send	qstart	qend	slen	qlen	evalue	bitscore	length	mismatch	gaps	pident	qcovs	total-query-coverage	gene	protein	group	originated-from' -cx $wd/all.VFDB-blast.tab
	#unoconv -i FilterOptions=09,,system,1 -f xls $wd/all.VFDB-blast.tab

	cp $wd/all.VFDB-blast.tab $wd/all.VFDB-blast.tab.tmp1
	cp $wd/all.VFDB-blast.tab.tmp1 $wd/all.txt.1.tmp
	sed -i 's/ /\t/g' $wd/all.VFDB-blast.tab

	sed -i 's/ /_/g' $wd/all.txt.1.tmp
	awk -F'\t' 'FNR >1 {print $17}' $wd/all.txt.1.tmp > $wd/all.txt.2.tmp
	sed -i 's/  /===/' $wd/all.txt.2.tmp
	sed -i 's/  /===/' $wd/all.txt.2.tmp
	cat $wd/all.txt.2.tmp | sort | uniq > $wd/all.txt.3.tmp 

	(rm $wd/Virulence_gene_frequency.csv.1.tmp) > /dev/null 2>&1 
	for F2 in $(cat $wd/all.txt.3.tmp); do
		V1=$(grep -c "$F2" $wd/all.txt.2.tmp)
		echo $F2 $V1 >> $wd/Virulence_gene_frequency.csv.1.tmp
	done

	cat $wd/Virulence_gene_frequency.csv.1.tmp | sort -k 2,2rn $wd/Virulence_gene_frequency.csv.1.tmp > $wd/Virulence_gene_frequency.csv.2.tmp

	awk -f /home/groups/VEO/scripts_for_users/supplementary_scripts/vlookup-VFDB.2.awk /work/groups/VEO/databases/VFDB/v2021/VFDB-annotations.2.txt $wd/Virulence_gene_frequency.csv.2.tmp > $wd/Virulence_gene_frequency.csv.3.tmp

	paste $wd/Virulence_gene_frequency.csv.2.tmp $wd/Virulence_gene_frequency.csv.3.tmp > $wd/Virulence_gene_frequency.csv

	ex -sc '1i|Virulence-gene frequency protein group originated-from' -cx $wd/Virulence_gene_frequency.csv
	sed -i 's/ /\t/g' $wd/Virulence_gene_frequency.csv

	sed -i 's/===/ /g' $wd/Virulence_gene_frequency.csv
	sed -i 's/_/ /g' $wd/Virulence_gene_frequency.csv
	sed -i 's/_/ /g' $wd/Virulence_gene_frequency.csv
	#unoconv -i FilterOptions=09,,system,1 -f xls $wd/Virulence_gene_frequency.csv

	echo "summarising virulence gene blast analysis completed"
exit
# ###############################################################################
# ## step-04: Creating matrix out of VFDB blast results

# 	echo "running matrix for VFDB"

# 	for F1 in $(cat $list);do
# 		awk -F'\t' 'FNR >1 {print $17}' $wd/$F1.VFDB-blast.csv | sed 's/ /_/g' > $wd/tmp/$F1.VFDB-blast.csv.tmp
# 			(rm $wd/$F1.gene-count.tmp1) > /dev/null 2>&1 
# 			for V1 in $(cat $wd/all.txt.3.tmp);do
# 			V2=$(awk '{count[$1]++} END {print count["'$V1'"]}' $wd/tmp/$F1.VFDB-blast.csv.tmp)
# 			echo $V2 >> $wd/$F1.gene-count.tmp1
# 			done
# 		awk '{for (i=1; i<= NF; i++) {if($i > 1) { $i=1; } } print }' $wd/$F1.gene-count.tmp1 > $wd/$F1.gene-count.tmp2
# 		ex -sc '1i|'$F1'' -cx $wd/$F1.gene-count.tmp1
# 		ex -sc '1i|'$F1'' -cx $wd/$F1.gene-count.tmp2
# 		sed -i -e 's/^$/0/' $wd/$F1.gene-count.tmp1
# 		sed -i -e 's/^$/0/' $wd/$F1.gene-count.tmp2
# 	done

# 	cp $wd/all.txt.3.tmp $wd/all.txt.4.tmp
# 	sed -i 's/$/:c/' $wd/all.txt.4.tmp
# 	sed -i '1i\===\' $wd/all.txt.4.tmp
# 	paste $wd/all.txt.4.tmp $wd/*.gene-count.tmp1 > $wd/matrix.csv.tmp1
# 	paste $wd/all.txt.4.tmp $wd/*.gene-count.tmp2 > $wd/matrix_1-0.csv.tmp2

# 	##-----------------------------------------------------------------------------
# 	## transpose
# 	awk '
# 	{ 
# 		for (i=1; i<=NF; i++)  {
# 			a[NR,i] = $i
# 		}
# 	}
# 	NF>p { p = NF }
# 	END {    
# 		for(j=1; j<=p; j++) {
# 			str=a[1,j]
# 			for(i=2; i<=NR; i++){
# 				str=str" "a[i,j];
# 			}
# 			print str
# 		}
# 	}' $wd/matrix.csv.tmp1 > $wd/matrix.csv

# 	awk '
# 	{ 
# 		for (i=1; i<=NF; i++)  {
# 			a[NR,i] = $i
# 		}
# 	}
# 	NF>p { p = NF }
# 	END {    
# 		for(j=1; j<=p; j++) {
# 			str=a[1,j]
# 			for(i=2; i<=NR; i++){
# 				str=str" "a[i,j];
# 			}
# 			print str
# 		}
# 	}' $wd/matrix_1-0.csv.tmp2 > $wd/matrix_1-0.csv

# 	##-----------------------------------------------------------------------------

# 	sed -i 's/===//g' $wd/matrix.csv
# 	sed -i 's/===//g' $wd/matrix_1-0.csv
# 	sed -i 's/ /,/g' $wd/matrix.csv
# 	sed -i 's/ /,/g' $wd/matrix_1-0.csv

# 	rm $wd/*.tmp1
# 	rm $wd/*.tmp2
# 	rm $wd/Virulence_gene_frequency.csv.1.tmp

# 	echo "finished matrix for VFDB"	

###############################################################################
echo "Completed.. Virulence gene blast ---------------------------------------"
###############################################################################
