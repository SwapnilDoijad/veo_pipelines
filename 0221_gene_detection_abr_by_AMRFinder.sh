#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "started.... AMRFinder --------------------------------------------------"
###############################################################################
## step-01: file and directory preparation

    pipeline=0221_gene_detection_abr_by_AMRFinder
    wd=results/$pipeline

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

    # create_directories_structure_1 $wd
    # split_list $wd $list
    # submit_jobs $wd $pipeline

###############################################################################
## step-02: waiting for the completion of the jobs

    # for i in $(cat $list); do
    #     wait_for_file_existence_and_completion "$wd/raw_files/$i.csv"
    # done

###############################################################################
## step-03: post-processing : calculate Abr-gene frequency

    (sed -i '/symbol/d' $wd/tmp/all.txt)> /dev/null 2>&1
                    # heading_list=$(head -1 $list)
                    # heading=$( cat $wd/results/$heading_list.csv | head -1  )
                    # ex -sc "1i|$heading" -cx $wd/tmp/all.txt

    cp $wd/tmp/all.txt $wd/tmp/all.csv # create all.csv earlier and remove this step  
                    ## ssconvert $wd/tmp/all.csv $wd/tmp/all.csv.xlsx
                    #------
    sed 's/ /_/g' $wd/tmp/all.txt > $wd/tmp/all.txt.1.tmp
    cut -f6,7,8,9,10,11,12 -d$'\t' $wd/tmp/all.txt.1.tmp | awk '{if(NR>1)print}' > $wd/tmp/all.txt.2.tmp
    sed -i 's/\t/===/g' $wd/tmp/all.txt.2.tmp
    cat $wd/tmp/all.txt.2.tmp | sed 's/===/=/g' | sort -t '=' -k3,3 -k4,4 -k5,5 -k6,6 -k7,7 | sed 's/=/===/g' | uniq > $wd/tmp/all.txt.3.tmp 

    (rm $wd/tmp/Abr_gene_frequency.csv.tmp)> /dev/null 2>&1
    for F2 in $(cat $wd/tmp/all.txt.3.tmp); do
        V1=$(grep -c "$F2" $wd/tmp/all.txt.2.tmp)
        echo $V1 $F2 >> $wd/tmp/Abr_gene_frequency.csv.tmp
    done

    cat $wd/tmp/Abr_gene_frequency.csv.tmp | sort -k 1,1rn > $wd/Abr_gene_frequency.tsv

    ex -sc '1i|frequency Abr-gene description Scope Element_type Element_subtype Class Subclass' -cx $wd/Abr_gene_frequency.tsv

    sed -i 's/===/\t/g' $wd/Abr_gene_frequency.tsv
    sed -i 's/ /\t/g' $wd/Abr_gene_frequency.tsv
    ##ssconvert $wd/tmp/Abr_gene_frequency.csv $wd/Abr_gene_frequency.csv.xlsx
    #rm $wd/tmp/Abr_gene_frequency.csv.tmp

# ###############################################################################
# ## Creating 1-0 matrix of ABR results
#     echo "running matrix for ABR-DB"
#     awk -F'===' '{print $1}' $wd/tmp/all.txt.3.tmp > $wd/tmp/all.txt.genes.tmp

#     for i in $(cat $list);do
#     cut -f6 -d$'\t' $wd/results/$i.csv | awk '{if(NR>1)print}' | sed 's/ /_/g' > $wd/tmp/$i.gene-list-to-count.tmp1
#         (rm $wd/tmp/$i.Abr-gene-count.tmp1) > /dev/null 2>&1 
#         for V1 in $(cat $wd/tmp/all.txt.genes.tmp); do
#         V2=$(awk '{count[$1]++} END {print count["'$V1'"]}' $wd/tmp/$i.gene-list-to-count.tmp1)
#         echo $V2 >> $wd/tmp/$i.Abr-gene-count.tmp1
#         done
#     awk '{for (i=1; i<= NF; i++) {if($i > 1) { $i=1; } } print }' $wd/tmp/$i.Abr-gene-count.tmp1 > $wd/tmp/$i.Abr-gene-count.tmp2
#     ex -sc '1i|'$i'' -cx $wd/tmp/$i.Abr-gene-count.tmp1
#     ex -sc '1i|'$i'' -cx $wd/tmp/$i.Abr-gene-count.tmp2
#     sed -i -e 's/^$/0/' $wd/tmp/$i.Abr-gene-count.tmp1
#     sed -i -e 's/^$/0/' $wd/tmp/$i.Abr-gene-count.tmp2
#     done
    
#     cp $wd/tmp/all.txt.genes.tmp $wd/tmp/all.txt.4.2.tmp
#     sed -i 's/$/:c/' $wd/tmp/all.txt.4.2.tmp
#     sed -i '1i\===\' $wd/tmp/all.txt.4.2.tmp

#     ls -1 $wd/tmp/*.Abr-gene-count.tmp1 | split -l 500 -d - lists1
#     for list1 in lists1* ; do
#         paste $(cat $list1) > $wd/tmp/merge.Abr-gene-count.tmp1.${list1##lists1}; 
#     done
#     paste $wd/tmp/merge.Abr-gene-count.tmp1.* > $wd/tmp/all.Abr-gene-count.1.tab
#     rm $wd/tmp/*.Abr-gene-count.tmp1.*
#     rm lists1*

#     ls -1 $wd/tmp/*.Abr-gene-count.tmp2  | split -l 500 -d - lists2
#     for list2 in lists* ; do
#         paste $(cat $list2) > $wd/tmp/merge.Abr-gene-count.tmp2.${list2##lists2}; 
#     done
#     paste $wd/tmp/merge.Abr-gene-count.tmp2.* > $wd/tmp/all.Abr-gene-count.2.tab
#     rm $wd/tmp/*.Abr-gene-count.tmp2.*
#     rm lists2*

#     paste $wd/tmp/all.txt.4.2.tmp $wd/tmp/all.Abr-gene-count.1.tab > $wd/tmp/matrix.csv.tmp1
#     paste $wd/tmp/all.txt.4.2.tmp $wd/tmp/all.Abr-gene-count.2.tab > $wd/tmp/matrix_1-0.csv.tmp2

#     awk '
#     { 
#         for (i=1; i<=NF; i++)  {
#             a[NR,i] = $i
#         }
#     }
#     NF>p { p = NF }
#     END {    
#         for(j=1; j<=p; j++) {
#             str=a[1,j]
#             for(i=2; i<=NR; i++){
#                 str=str" "a[i,j];
#             }
#             print str
#         }
#     }' $wd/tmp/matrix.csv.tmp1 > $wd/matrix.csv

#     awk '
#     { 
#         for (i=1; i<=NF; i++)  {
#             a[NR,i] = $i
#         }
#     }
#     NF>p { p = NF }
#     END {    
#         for(j=1; j<=p; j++) {
#             str=a[1,j]
#             for(i=2; i<=NR; i++){
#                 str=str" "a[i,j];
#             }
#             print str
#         }
#     }' $wd/tmp/matrix_1-0.csv.tmp2 > $wd/matrix_1-0.csv
# ###############################################################################
# ## Create final files
#     sed -i 's/===//g' $wd/matrix.csv
#     sed -i 's/===//g' $wd/matrix_1-0.csv
#     sed -i 's/ /,/g' $wd/matrix_1-0.csv 
#     echo "finished matrix for ABR-DB"
###############################################################################
## create plots
    source /home/groups/VEO/tools/python/biopython/bin/activate

###############################################################################
echo "Finished.... AMRFinder  ------------------------------------------------"
###############################################################################
