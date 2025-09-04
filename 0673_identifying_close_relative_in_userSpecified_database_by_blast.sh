#!/bin/bash
###############################################################################
## header
    pipeline=0673_identifying_close_relative_in_userSpecified_database_by_blast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline --------------------------------------"
###############################################################################
## preparation
    database_fasta=$(grep "my_database_fasta" $parameters | awk '{print $NF}')
    query_fasta_dir=$(grep "my_query_fasta_dir" $parameters | awk '{print $NF}')
    ls $query_fasta_dir/ | sed 's/.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt
    db_name=$(basename $database_fasta)

    create_directories_structure_1 $wd

    if [ ! -f $wd/blastdb/$db_name.ndb ]; then
        mkdir $wd/blastdb

        /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
        -in $database_fasta \
        -dbtype nucl \
        -out $wd/blastdb/$db_name
    fi

    split_list $wd $list
    submit_jobs $wd $pipeline
###############################################################################
