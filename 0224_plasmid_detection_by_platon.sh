###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0224_plasmid_detection_by_platon ---------------------------------"
###############################################################################
## step-01: file and directory preparation

    pipeline=0224_plasmid_detection_by_platon
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

###############################################################################
log "FINISHED : 0224_plasmid_detection_by_platon ---------------------------------"
###############################################################################