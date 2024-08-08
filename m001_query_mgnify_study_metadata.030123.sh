#!/bin/bash
###############################################################################
# 000 query mgnify study database 
###############################################################################
    T=`date '+%d%m%Y_%H%M%S'` 
    awk -F'\t' '{print $6}' /work/groups/VEO/databases/mgnify/mgnify.study.index.*.tab > /work/groups/VEO/databases/mgnify/scratch_files/mgnify.study.index.source-list.tab
    V1=$(awk -F':' '{print $2}' /work/groups/VEO/databases/mgnify/scratch_files/mgnify.study.index.source-list.tab | sort -u)

    echo "#####################################################################"
    echo "#studies    source"
    for F1 in $V1; do
        V2=$(awk -F':' '{print $2}' /work/groups/VEO/databases/mgnify/scratch_files/mgnify.study.index.source-list.tab | grep -o -i $F1 | wc -l | awk '{ printf "%04i\n", $0 }')
        echo "$V2       $F1"
    done
    echo "#####################################################################"

    echo "for which main source you would like to view sub-sources? (for e.g. Host-associated)"
    read source
    echo "#####################################################################"
    echo "#studies  sub-source"
    subsource_list=$(grep $source /work/groups/VEO/databases/mgnify/scratch_files/mgnify.study.index.source-list.tab | awk -F':' '{print $3}' | sort -u)
    for subsource in $subsource_list; do
        subsource_count=$(grep $source /work/groups/VEO/databases/mgnify/scratch_files/mgnify.study.index.source-list.tab | awk -F':' '{print $3}' | grep -o -i $subsource | wc -l | awk '{ printf "%04i\n", $0 }')
        echo "$subsource_count   $subsource"
    done
    echo "#####################################################################"
    echo "#studies   sub-sub-source"
    subsubsource_list=$(grep $source /work/groups/VEO/databases/mgnify/scratch_files/mgnify.study.index.source-list.tab | awk -F':' '{print $4}' | sort -u)
    for subsubsource in $subsubsource_list; do
        subsubsource_count=$(grep "$source" /work/groups/VEO/databases/mgnify/scratch_files/mgnify.study.index.source-list.tab | awk -F':' '{print $4}' | grep -o -i $subsubsource | wc -l | awk '{ printf "%04i\n", $0 }')
        echo "$subsubsource_count   $subsubsource"
    done
    echo "#####################################################################"

    echo "which source/sub-source/sub-sub-source ? 
    for e.g. sub-sub-source 'Hydrocarbon' " 
    read subsubsource
    grep subsubsource /work/groups/VEO/databases/mgnify/mgnify.study.index.*.tab | awk '{print $3}' > study_accession_list_for_"$source"_"$subsubsource".txt
    for F1 in $(cat study_accession_list_for_"$source"_"$subsubsource".txt); do
    echo  "/work/groups/VEO/databases/mgnify/studies/$F1" >> study_accession_path_"$source"_"$subsubsource".txt
    done

    echo "for details, see files at your home directory 
    study_accession_list_for_"$source"_"$subsubsource".txt
    study_accession_path_"$source"_"$subsubsource".txt"

exit




echo "study accesssion numbers for $user_source"
numstudies=$(grep $user_source /work/groups/VEO/databases/mgnify/mgnify.study.index.*.tab | awk '{print $3}')
echo $studies

echo "would you like to copy the study data to a directory? if yes provide path (for e.g. '/home/xa73pav/my_study') or type 'n' to exit"
read user_input
    if [ "$user_input" == "n" ]; then
    echo "exiting, bye!"
    exit
    else 
        for study in $studies; do
        cp -r  /work/groups/VEO/databases/mgnify/studies/$study $user_input
        done
        echo "data copy complete!"
    fi
