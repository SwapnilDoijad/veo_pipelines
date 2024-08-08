#!/bin/bash
###############################################################################
# 000 query mgnify sample database 
###############################################################################
    T=`date '+%Y%m%d_%H%M%S'` 

    echo "#####################################################################"
    head -1 /work/groups/VEO/databases/mgnify/mgnify.sample.index.*.tab | tr "\t" "\n" 
    #head -1 /work/groups/VEO/databases/mgnify/mgnify.sample.index.*.tab | tr "\t" "\n"
    echo "#####################################################################"
    echo "type which parameter you would like to search in? (for e.g. geo-loc-name)"
    read parameter
    echo "type search query (for e.g. spain)"
    read user_input_1
    (rm -rf "$parameter"_"$user_input_1") > /dev/null 2>&1
    (mkdir "$parameter"_"$user_input_1") > /dev/null 2>&1
    mydir="$parameter"_"$user_input_1"
    echo "searching..."
###############################################################################
    parameter_number=$(awk '$1 == "'$parameter'" {print $2}' /work/groups/VEO/databases/mgnify/supporting_file.tab)
###############################################################################

    count_for_user_input_1=$(awk -F'\t' 'NR==1 { for (i=1;i<=NF;++i) if ($i=="'$parameter'") { n=i; break }} { print $1, $n }' /work/groups/VEO/databases/mgnify/mgnify.sample.index.*.tab | grep -i $user_input_1 | wc -l)
    
    ## studies_for_query
    awk -F'\t' 'NR==1 { for (i=1;i<=NF;++i) if ($i=="'$parameter'") { n=i; break }} { print $1, $n }' /work/groups/VEO/databases/mgnify/mgnify.sample.index.*.tab | grep -i $user_input_1 | awk '{print $1}' | sed -e 's/_/\n/g' | sort -u > $mydir/mgnify_study_ids.txt
    studies_for_query=$(wc -l $mydir/mgnify_study_ids.txt | awk '{print $1}')

    
    (rm $mydir/mgnify_study_details.txt) > /dev/null 2>&1
    for F1 in $(cat $mydir/mgnify_study_ids.txt); do
        grep $F1 /work/groups/VEO/databases/mgnify/mgnify.study.index.*.tab >> $mydir/mgnify_study_details.txt
        study_ids=$(grep $F1 $mydir/mgnify_study_details.txt | awk '{print $3}')
        echo "databases/mgnify/studies/$study_ids" >> $mydir/mgnify_study_path.txt
    done
    paste $mydir/mgnify_study_details.txt $mydir/mgnify_study_path.txt > study_metadata_"$parameter"_"$user_input_1".tab
    
    echo -e "mgnify-id\tsample-accession\tbiosample\tsource\tlatitude\tlongitude\tcollection-date\tgeo-loc-name\tsample-desc\tsample-name\tsample-alias\thost-tax-id\tspecies\tlast-update\tanalysis-completed\tenvironment-biome\tenvironment-feature\tenvironment-material\tENA_checklist\tinvestigation_type\tgeographic_location_(country_and/or_sea,region)\tgeographic_location_(latitude)\tgeographic_location_(longitude)\tgeographic_location_(depth)\taltitude\televation\tcollection_date\tenvironment_(biome)\tenvironment_(feature)\tenvironment_(material)\tenvironmental_package\tsex\thost_sex\tbody_site\thost_common_name\tanonymized_name\tcommon_name\tbody_habitat\tcollection_time\tNCBI_sample_classification\tsequencing_method\tinstrument_model" > sample_metadata_"$parameter"_"$user_input_1".tab
    awk 'BEGIN{IGNORECASE=1} $8 ~ "spain" {print $0}' /work/groups/VEO/databases/mgnify/mgnify.sample.index.*.tab >> sample_metadata_"$parameter"_"$user_input_1".tab
    
    non_duplicate_samples_available_tmp1=$(wc -l sample_metadata_"$parameter"_"$user_input_1".tab | awk '{print $1}')
    non_duplicate_samples_available=$(($non_duplicate_samples_available_tmp1-1))
    echo "     
    studies: $studies_for_query 
    samples: $non_duplicate_samples_available"
    echo "for details, see files at your home directory 
    study_metadata_"$parameter"_"$user_input_1".tab
    sample_metadata_"$parameter"_"$user_input_1".tab"

    #(rm -rf $mydir) > /dev/null 2>&1
###############################################################################