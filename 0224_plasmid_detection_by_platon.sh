###############################################################################
## header
    pipeline=0224_plasmid_detection_by_platon
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0224_plasmid_detection_by_platon ---------------------------------"
###############################################################################
## step-01: file and directory preparation

    fasta_file_dir=$(grep "my_fasta_path" $parameters | awk '{print $2}')
    ls $fasta_file_dir | sed 's/\.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
log "FINISHED : 0224_plasmid_detection_by_platon ---------------------------------"
###############################################################################