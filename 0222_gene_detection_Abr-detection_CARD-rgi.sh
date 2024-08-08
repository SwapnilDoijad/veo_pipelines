#!/bin/bash
###############################################################################
#22 CARD-ABR blast
## run in conda base environment
###############################################################################
echo "started....Antibiotic gene detection by CARD ----------------------------"
###############################################################################
## Initial file and directory preparation
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate rgi_v6.0.2

    echo "provide list file (for e.g. all)"
    echo "---------------------------------------------------------------------"
    ls list.*.txt | sed 's/ /\n/g'
    echo "---------------------------------------------------------------------"
    read l
    list=$(echo "list.$l.txt")
    s=$(echo "_$l")
    
    ##-----------------------------------------------------------------------------
    if [ -d results/0040_assembly/all_fasta ]; then
        fasta_directory=all_fasta
        elif [ -d results/0040_assembly/all_fasta_prophage ]; then
        fasta_directory=all_fasta_prophage
        else
        echo "fasta directory not found"
        exit
    fi
    ##-----------------------------------------------------------------------------
    (mkdir -p results/0222_CARD-AR_results"$s"/results)> /dev/null 2>&1
    (mkdir -p results/0222_CARD-AR_results"$s"/tmp)> /dev/null 2>&1
    ##--------------------
    card_software_version=$(rgi main -v)
    card_database_version=$(rgi database -v)
    alignment_tool=$(echo BLAST) #{DIAMOND,BLAST}
###############################################################################
## run card
    for F1 in $(cat $list); do
        echo $F1
        if [ ! -f results/0222_CARD-AR_results"$s"/results/$F1.txt ]; then
            echo "runnning... CARD-ABR v$card_software_version for $F1 with $card_database_version database using $alignment_tool alignment_tool"
            rgi main -i results/0040_assembly/$fasta_directory/$F1.fasta -o results/0222_CARD-AR_results"$s"/results/$F1 -a $alignment_tool -t contig --clean
            #sudo rgi main -i results/08_annotation/raw_files/And1463/And1463.faa -o results/0222_CARD-AR_results"$s"/results/$F1 -a DIAMOND -t protein --clean
            #/home/swapnil/tools/rgi-5.0.0/rgi-5.0.0/
            #rgi main -i results/08_annotation/raw_files/$F1/$F1.faa -o results/0222_CARD-AR_results"$s"/results/$F1 -a $alignment_tool -t protein --clean
            #rgi main -i results/08_annotation/raw_files/$F1/$F1.faa -o results/0222_CARD-AR_results"$s"/results/$F1 -a $alignment_tool -t protein --clean #> /dev/null 2>&1
            else
            echo "CARD already finished for $F1"
       fi
    done
###############################################################################
## create a heatmap
    if [ ! -f results/0222_CARD-AR_results"$s"/*.png ] ; then 
    (rgi heatmap --input results/0222_CARD-AR_results"$s"/results/ --output results/0222_CARD-AR_results"$s"/) > /dev/null 2>&1
    fi
###############################################################################
##calculate Abr-gene frequency
    (rm results/0222_CARD-AR_results"$s"/tmp/all.txt)> /dev/null 2>&1
    for F1 in $(cat $list); do
    awk 'FNR>1' results/0222_CARD-AR_results"$s"/results/$F1.txt >> results/0222_CARD-AR_results"$s"/tmp/all.txt
    done
    #-----
    if grep -Fxq "ORF_ID	CONTIG	START	STOP	ORIENTATION	CUT_OFF	PASS_EVALUE	Best_Hit_evalue	Best_Hit_ARO	Best_Identities	ARO	ARO_name	Model_type	SNP	Best_Hit_ARO_category	ARO_category	PASS_bitscore	Best_Hit_bitscore	bit_score	Predicted_DNA	Predicted_Protein	CARD_Protein_Sequence	LABEL	ID	Model_id" results/0222_CARD-AR_results"$s"/tmp/all.txt; then
    :
    else
    ex -sc '1i|ORF_ID	CONTIG	START	STOP	ORIENTATION	CUT_OFF	PASS_EVALUE	Best_Hit_evalue	Best_Hit_ARO	Best_Identities	ARO	ARO_name	Model_type	SNP	Best_Hit_ARO_category	ARO_category	PASS_bitscore	Best_Hit_bitscore	bit_score	Predicted_DNA	Predicted_Protein	CARD_Protein_Sequence	LABEL	ID	Model_id' -cx results/0222_CARD-AR_results"$s"/tmp/all.txt
    fi
    cp results/0222_CARD-AR_results"$s"/tmp/all.txt results/0222_CARD-AR_results"$s"/tmp/all.csv # create all.csv earlier and remove this step  
    #ssconvert results/0222_CARD-AR_results"$s"/tmp/all.csv results/0222_CARD-AR_results"$s"/tmp/all.csv.xlsx
    #------
    cp results/0222_CARD-AR_results"$s"/tmp/all.txt results/0222_CARD-AR_results"$s"/tmp/all.txt.1.tmp
    sed -i 's/ /_/g' results/0222_CARD-AR_results"$s"/tmp/all.txt.1.tmp
    awk -F'\t' 'NR>1 {print $9,'\t',$15}' results/0222_CARD-AR_results"$s"/tmp/all.txt.1.tmp > results/0222_CARD-AR_results"$s"/tmp/all.txt.2.tmp
    sed -i 's/  /===/' results/0222_CARD-AR_results"$s"/tmp/all.txt.2.tmp 
    cat results/0222_CARD-AR_results"$s"/tmp/all.txt.2.tmp | sort | uniq > results/0222_CARD-AR_results"$s"/tmp/all.txt.3.tmp 

    (rm results/0222_CARD-AR_results"$s"/tmp/Abr_gene_frequency.csv.tmp) > /dev/null 2>&1
    for F2 in $(cat results/0222_CARD-AR_results"$s"/tmp/all.txt.3.tmp); do
    V1=$(grep -c "$F2" results/0222_CARD-AR_results"$s"/tmp/all.txt.2.tmp)
    echo $V1 $F2 >> results/0222_CARD-AR_results"$s"/tmp/Abr_gene_frequency.csv.tmp
    done

    cat results/0222_CARD-AR_results"$s"/tmp/Abr_gene_frequency.csv.tmp | sort -k 1,1rn results/0222_CARD-AR_results"$s"/tmp/Abr_gene_frequency.csv.tmp > results/0222_CARD-AR_results"$s"/Abr_gene_frequency.tab

    ex -sc '1i|frequency Abr-gene description' -cx results/0222_CARD-AR_results"$s"/Abr_gene_frequency.tab

    sed -i 's/===/ /g' results/0222_CARD-AR_results"$s"/Abr_gene_frequency.tab
    sed -i -e 's/ /\t/g' results/0222_CARD-AR_results"$s"/Abr_gene_frequency.tab
    #ssconvert results/0222_CARD-AR_results"$s"/Abr_gene_frequency.tab results/0222_CARD-AR_results"$s"/Abr_gene_frequency.tab.xlsx
    rm results/0222_CARD-AR_results"$s"/tmp/Abr_gene_frequency.csv.tmp
###############################################################################
## Creating 1-0 matrix of ABR results

    echo "running matrix for ABR-DB"
    for F1 in $(cat $list);do
        awk -F'===' '{print $1}' results/0222_CARD-AR_results"$s"/tmp/all.txt.3.tmp > results/0222_CARD-AR_results"$s"/tmp/all.txt.4.tmp
        awk -F'\t' '{print $9}' results/0222_CARD-AR_results"$s"/results/$F1.txt | sed 's/ /_/g' > results/0222_CARD-AR_results"$s"/tmp/$F1.gene-list-to-count.tmp1
            (rm results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp1) > /dev/null 2>&1 
            for V1 in $(cat results/0222_CARD-AR_results"$s"/tmp/all.txt.4.tmp);do
                V2=$(awk '{count[$1]++} END {print count["'$V1'"]}' results/0222_CARD-AR_results"$s"/tmp/$F1.gene-list-to-count.tmp1)
                echo $V2 >> results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp1
            done
        awk '{for (i=1; i<= NF; i++) {if($i > 1) { $i=1; } } print }' results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp1 > results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp2
        sed -i -e '1s/^/'$F1'\n/' results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp1
        sed -i -e '1s/^/'$F1'\n/' results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp2
        sed -i -e 's/^$/0/' results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp1
        sed -i -e 's/^$/0/' results/0222_CARD-AR_results"$s"/tmp/$F1.Abr-gene-count.tmp2
    done

    sed -i 's/,/_/g' results/0222_CARD-AR_results"$s"/tmp/all.txt.4.tmp
    cp results/0222_CARD-AR_results"$s"/tmp/all.txt.4.tmp results/0222_CARD-AR_results"$s"/tmp/all.txt.4.2.tmp
    sed -i 's/$/:c/' results/0222_CARD-AR_results"$s"/tmp/all.txt.4.2.tmp
    sed -i '1i\===\' results/0222_CARD-AR_results"$s"/tmp/all.txt.4.2.tmp
    paste results/0222_CARD-AR_results"$s"/tmp/all.txt.4.2.tmp results/0222_CARD-AR_results"$s"/tmp/*.Abr-gene-count.tmp1 > results/0222_CARD-AR_results"$s"/tmp/matrix.csv.tmp1
    paste results/0222_CARD-AR_results"$s"/tmp/all.txt.4.2.tmp results/0222_CARD-AR_results"$s"/tmp/*.Abr-gene-count.tmp2 > results/0222_CARD-AR_results"$s"/tmp/matrix_1-0.csv.tmp2

    awk '
    { 
        for (i=1; i<=NF; i++)  {
            a[NR,i] = $i
        }
    }
    NF>p { p = NF }
    END {    
        for(j=1; j<=p; j++) {
            str=a[1,j]
            for(i=2; i<=NR; i++){
                str=str" "a[i,j];
            }
            print str
        }
    }' results/0222_CARD-AR_results"$s"/tmp/matrix.csv.tmp1 > results/0222_CARD-AR_results"$s"/matrix.csv

    awk '
    { 
        for (i=1; i<=NF; i++)  {
            a[NR,i] = $i
        }
    }
    NF>p { p = NF }
    END {    
        for(j=1; j<=p; j++) {
            str=a[1,j]
            for(i=2; i<=NR; i++){
                str=str" "a[i,j];
            }
            print str
        }
    }' results/0222_CARD-AR_results"$s"/tmp/matrix_1-0.csv.tmp2 > results/0222_CARD-AR_results"$s"/matrix_1-0.csv

    sed -i 's/===//g' results/0222_CARD-AR_results"$s"/matrix.csv
    sed -i 's/===//g' results/0222_CARD-AR_results"$s"/matrix_1-0.csv
    sed -i 's/,/_/g' results/0222_CARD-AR_results"$s"/matrix_1-0.csv 

    echo "finished matrix for ABR-DB"
###############################################################################
