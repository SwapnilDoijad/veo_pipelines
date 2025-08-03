###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0067p_identification_contigs_by_CAT -------------------------"
###############################################################################
## step-01: file and directory preparation
    pipeline=0067_identification_contigs_by_CAT_BAT_RAT
    wd=results/$pipeline

    if [ -f list.fasta2.txt ]; then 
        list=list.fasta2.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

###############################################################################
## post-processing 
    if [ -f $wd/tmp/tmp_files/$i.percentage.txt ] ; then 
        rm $wd/tmp/tmp_files/filepath.txt > /dev/null 2>&1
        mkdir $wd/tmp/tmp_files > /dev/null 2>&1
        for i in $(cat $list); do
            log "extracting contigs from CAT for $i"
            cat $wd/raw_files/$i/CAT/$i.summary.txt \
            | sed 's/ /_/g' | sed 's/NA/unknown/g' | grep -v '#' | awk '{print $1, $2, $3}'| sed 's/ /\t/g' \
            > $wd/tmp/tmp_files/$i.CAT.txt

            python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0067_identification_contigs_by_CAT_BAT_RAT.percentage.py \
            -i $wd/tmp/tmp_files/$i.CAT.txt \
            -o $wd/tmp/tmp_files/$i.percentage.txt

            echo "$wd/tmp/tmp_files/$i.percentage.txt" \
            >> $wd/tmp/tmp_files/filepath.txt
        done
    fi 

    source /home/groups/VEO/tools/biopython/myenv/bin/activate
    # python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0067_identification_contigs_by_CAT_BAT_RAT.matrix.py
    # awk -F',' 'NR>1 {print $1}' $wd/tmp/tmp_files/combined_table.csv | sort -u > $wd/tmp/tmp_files/combined_table.list.txt
    for rank in $(cat $wd/tmp/tmp_files/combined_table.list.txt ); do 
        echo "creating table for $rank"
        python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0067_identification_contigs_by_CAT_BAT_RAT.plot.py \
        -i $wd/tmp/tmp_files/combined_table.csv \
        -r $rank \
        -o $wd/raw_files/$rank.plot.png
    done
    deactivate
###############################################################################
## footer
    log "ENDED : 0067p_identification_contigs_by_CAT -------------------------"
###############################################################################