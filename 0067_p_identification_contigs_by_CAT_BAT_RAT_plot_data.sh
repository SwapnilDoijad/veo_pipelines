###############################################################################
## header
    pipeline=0067_identification_contigs_by_CAT_BAT_RAT
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline -------------------------"
###############################################################################
## step-01: file and directory preparation
    list=list.$pipeline.txt
##############################################################################
## post-processing 
    if [ -f $wd/tmp/tmp_files/$i.percentage.txt ] ; then 
        rm $wd/tmp/tmp_files/filepath.txt > /dev/null 2>&1
        mkdir $wd/tmp/tmp_files > /dev/null 2>&1
        for i in $(cat $list); do
            log "extracting contigs from CAT for $i"
            cat $raw_files/$i/CAT/$i.summary.txt \
            | sed 's/ /_/g' | sed 's/NA/unknown/g' | grep -v '#' | awk '{print $1, $2, $3}'| sed 's/ /\t/g' \
            > $wd/tmp/tmp_files/$i.CAT.txt

            python3 $suppl_scripts/$pipeline.percentage.py \
            -i $wd/tmp/tmp_files/$i.CAT.txt \
            -o $wd/tmp/tmp_files/$i.percentage.txt

            echo "$wd/tmp/tmp_files/$i.percentage.txt" \
            >> $wd/tmp/tmp_files/filepath.txt
        done
    fi 

    source /home/groups/VEO/tools/biopython/myenv/bin/activate
    # python3 $suppl_scripts/$pipeline.matrix.py
    # awk -F',' 'NR>1 {print $1}' $wd/tmp/tmp_files/combined_table.csv | sort -u > $wd/tmp/tmp_files/combined_table.list.txt
    for rank in $(cat $wd/tmp/tmp_files/combined_table.list.txt ); do 
        echo "creating table for $rank"
        python3 $suppl_scripts/$pipeline.plot.py \
        -i $wd/tmp/tmp_files/combined_table.csv \
        -r $rank \
        -o $raw_files/$rank.plot.png
    done
    deactivate
###############################################################################
## footer
    log "ENDED : $pipeline -------------------------"
###############################################################################