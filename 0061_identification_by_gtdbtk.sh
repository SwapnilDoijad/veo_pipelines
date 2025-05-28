
#!/bin/bash
###############################################################################
    pipeline=0061_identification_by_gtdbtk
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED: $pipeline -------------------------------------------"
###############################################################################
## step-01: preparation

    fasta_file_dir=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
    ls $fasta_file_dir/*.fasta | awk -F'/' '{print $NF}' | sed 's/\.fasta//g' | grep -v "samtools" > list.$pipeline.txt

    > list.$pipeline.tmp
    for i in $(cat list.$pipeline.txt); do 
        echo -e "$fasta_file_dir/$i.fasta\t$i" \
        >> list.$pipeline.tmp
    done 
    list=list.$pipeline.tmp


    ## gtdbtk can process batchfile, so no need to split the list (if number of samples are not very high)
    create_directories_structure_1 $wd
    # split_list $wd $list
    # submit_jobs $wd $pipeline
    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0061_identification_by_gtdbtk.sbatch
##############################################################################
    echo "ENDED: $pipeline -------------------------------------------"
###############################################################################
