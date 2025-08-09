###############################################################################
## output
# 1 Percentage of fragments covered by the clade rooted at this taxon
# 2 Number of fragments covered by the clade rooted at this taxon
# 3 Number of fragments assigned directly to this taxon
# 4 A rank code, indicating (U)nclassified, (R)oot, (D)omain, (K)ingdom, (P)hylum, (C)lass, (O)rder, (F)amily, (G)enus, or (S)pecies. Taxa that are not at any of these 10 ranks have a rank code that is formed by using the rank code of the closest ancestor rank with a number indicating the distance from that rank. E.g., "G2" is a rank code indicating a taxon is between genus and species and the grandparent taxon is at the genus rank.
# 5 NCBI taxonomic ID number
# 6 Indented scientific name
###############################################################################
pipeline=0062_identification_by_kraken2
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
    log "STARTED: $pipeline"
    
    data_path=$(grep "my_data_dir" $parameters | awk '{print $2}')
    input_file_type=$( grep "my_input_file_type" $parameters | awk -F'\t' '{print $2}')

    if [  "$input_file_type" == "f" ] ; then 
        ls $data_path/ | sed 's/\.fasta//g' > list.$pipeline.txt
    elif [ "$input_file_type" == "r" ] ; then
        ls $data_path/ | sed 's/_R1.fastq.gz//g' | sed 's/_R2.fastq.gz//g' | sort -u > list.$pipeline.txt
    fi

    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

    echo -e "id\tPercFrag\tNumbFrag\tNumbFragAssig\trank\tNCBIid\tSpecies" > $wd/report.csv
###############################################################################
    log "ENDED: $pipeline"
###############################################################################