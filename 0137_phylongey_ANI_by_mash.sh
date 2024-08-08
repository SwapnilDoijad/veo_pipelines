#!/bin/bash
echo "Hi Swapnil, transpose step needs higher memory, runs well on log-in node but doesnt run on working node"
###############################################################################
## header
    pipeline=0137_phylongey_ANI_by_mash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline started --------------------------------------"
############################################################################### 
## 00 preparations 
    fasta_path=$(grep "my_fasta_path" $parameters | awk '{print $NF}')
    ls $fasta_path/ | sed 's/.fasta//g' > list.fasta.txt
    list=list.fasta.txt

    (mkdir -p $raw_files/tmp)> /dev/null 2>&1
    (mkdir -p $raw_files/msh/distance)> /dev/null 2>&1
    (mkdir -p $raw_files/msh/distance/tmp)> /dev/null 2>&1
 
    # Specify the number of CPU cores you want to use
    num_cores=80 
###############################################################################
## step-03: sketching
    if [ ! -f $raw_files/msh/mash_sketch.msh ] ; then 
        log "STARTED : $pipeline : sketching"
        ( /home/groups/VEO/tools/mash/v2.3/mash sketch -p 80 -s 100 -o $raw_files/msh/mash_sketch.msh $fasta_path/*.fasta )> /dev/null 2>&1
        log "FINISHED: $pipeline : sketching"
        else
        log "ALREADY FINISHED : $pipeline : sketching"
    fi 
###############################################################################
## step-04: mashing
    if [ ! -f $raw_files/tmp/all.distance.for_R.tab ] ; then 
        log "STARTED : $pipeline : mashing"
        /home/groups/VEO/tools/mash/v2.3/mash triangle -p 80 $raw_files/msh/mash_sketch.msh > $raw_files/tmp/all.distance.for_R.tab
        log "FINISHED: $pipeline : mashing"
        else 
        log "ALREADY FINISHED : $pipeline : mashing"
    fi
###############################################################################
## step-05: post-calculations 
    log "STARTED : $pipeline :  running post-calculations"  
    cat $raw_files/tmp/all.distance.for_R.tab | sed '1d' | sed 's/\.fasta//g' > $raw_files/tmp/all.distance.for_R.out.tab
    cat $raw_files/tmp/all.distance.for_R.out.tab | sed "s|$fasta_path/||g" > $raw_files/tmp/all.distance.for_R.out.2.tab
    
    cp $raw_files/tmp/all.distance.for_R.out.2.tab results/out.tab
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/transpose.mash.sh
    mv results/out.t.tab $raw_files/tmp/all.distance.for_R.out.t.tab
    awk 'NR==FNR{ a[NR+1]=$0 FS 0; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' $raw_files/tmp/all.distance.for_R.out.2.tab $raw_files/tmp/all.distance.for_R.out.t.tab > $raw_files/tmp/all.distance.for_R.matrix.tab
    sed -i 's/ /\t/g' $raw_files/tmp/all.distance.for_R.matrix.tab
    # sed -e "1,/0/s/0//" $raw_files/tmp/all.distance.for_R.matrix.tab > $raw_files/tmp/all.distance.for_R.matrix.tab

    R1_rows=$(wc -l $raw_files/tmp/all.distance.for_R.matrix.tab | awk '{print $1}' )
    R2_columns=$(head -1 $raw_files/tmp/all.distance.for_R.matrix.tab |  sed 's/\t/\n/g' | wc -l ) 
    echo "rows:$R1_rows columns:$R2_columns"

    #------------------------------------------------------------------------------
    # for_R
    if [ ! "$R1_rows" == "$R2_columns" ] ; then
        echo "rows and cloumns numbers are not OK for R, could not run plot_and_tree.mash-distance.r"
        else
        echo "running R"
        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate R
        cp $raw_files/tmp/all.distance.for_R.matrix.tab $wd/matrix.tab
        Rscript /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/plot_and_tree.mash-distance.r
    fi

    source /home/groups/VEO/tools/biopython/myenv/bin/activate 
    if [ -f results/0137_phylongey_ANI_by_mash/raw_files/matrix.tab.tree.phangorn.nwk ] ; then 
        python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/export_phylogenomic_tip_labels.py \
        -i results/0137_phylongey_ANI_by_mash/matrix.tab.tree.phangorn.nwk \
        -o results/0137_phylongey_ANI_by_mash/matrix.tab.tree.phangorn.nwk.tip_labels
    fi
    deactivate

    # rm results/out.tab
    echo "post-calculations finished"

exit
###############################################################################
## Mash with GGRaSP package 
    echo "running GGRaSP package"
    for F1 in $(cat $list); do
    F2=$(echo $F1 | awk -F'.' '{print $1}')
    awk -F'\t' -v col="$F2" 'NR==1{for(i=1;i<=NF;i++){if($i==col){c=i;break}} print $c} NR>1{print (1-$c)*100}' $wd/tmp/all.distance.for_R.tab > $wd/msh/distance/tmp/$F1.ggrasp.tmp
    done
    ## get first-name column
    awk -F'\t' '{print $1}' $wd/tmp/all.distance.for_R.tab | sed '1d' > $wd/tmp/list.ggrasp

    cat $wd/tmp/list.ggrasp | sed '1i\\' > $wd/msh/distance/all.ggrasp.tab
    for F1 in $(cat $wd/tmp/list.ggrasp); do
    paste $wd/msh/distance/all.ggrasp.tab $wd/msh/distance/tmp/$F1.ggrasp.tmp > $wd/msh/distance/all.ggrasp.tab.tmp
    mv $wd/msh/distance/all.ggrasp.tab.tmp $wd/msh/distance/all.ggrasp.tab
    done

    mv $wd/msh/distance/all.ggrasp.tab $wd/tmp/all.distance.for_GGRaSP.tab
    #------------------------------------------------------------------------------
    G1_rows=$(wc -l $wd/tmp/all.distance.for_GGRaSP.tab | awk '{print $1}' )
    G2_columns=$(head -n1 $wd/tmp/all.distance.for_GGRaSP.tab |  sed 's/\t/\n/g' | wc -l)
    echo "$G1_rows $G2_columns "
    #------------------------------------------------------------------------------
    # for_GGRaSP get a representative of a clutster at 95% (-h 5)
    if [ ! "$G1_rows" == "$G2_columns" ] ; then
    echo "rows and cloumns numbers are not OK for GGRaSP, could not run all.distance.for_GGRaSP.tab"
    else
    echo "running ggrasp.R"
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i $wd/tmp/all.distance.for_GGRaSP.tab -d 100 -h 5.0000 -o $wd/representative_of_a_clusters_at_95.0000_250000nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i $wd/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0100 -o $wd/representative_of_a_clusters_at_99.9900_000500nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i $wd/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0050 -o $wd/representative_of_a_clusters_at_99.9950_000250nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i $wd/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0010 -o $wd/representative_of_a_clusters_at_99.9990_000050nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i $wd/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0001 -o $wd/representative_of_a_clusters_at_99.9999_000005nucl-5Mb-genome_ANI )> /dev/null 2>&1
    fi
    
    #----------------------------------------------------------------------------
    ## for 
        ls $wd//*.medoids.txt | awk -F'/' '{print $NF}' > $wd/tmp/list.ggrasp.tmp
            for F3 in $(cat $wd/tmp/list.ggrasp.tmp ); do
                echo "running mash and R for $F3"
                name=$( echo $F3 | awk -F'/' '{print $NF}' )
                mkdir $wd/fasta_$F3
                for files in $(cat $wd/$F3 ); do
                    cp results/0040_assembly/all_fasta/"$files".fasta $wd/fasta_$F3/
                done
                #echo "sketching"
                (mash sketch -o $wd/msh/mash_sketch.$name.msh $wd/fasta_$F3/*.fasta)> /dev/null 2>&1
                rm -rf $wd/fasta_$F3
                #echo "mashing"
                mash dist $wd/msh/mash_sketch.$name.msh $wd/msh/mash_sketch.$name.msh | square_mash > $wd/tmp/all.distance.for_R.$name.tab

                #------------------------------------------------------------------------------
                # for_R
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.tab/all.distance.for_R.$name.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                Rscript /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.$name.tab/all.distance.for_R.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                (mv Rplots.pdf $wd/$name.Rplots.pdf)> /dev/null 2>&1
                (mv tree.nwk $wd/$name.tree.nwk)> /dev/null 2>&1
            done
exit
###############################################################################
## thinspace
## did not work as exepcted so not added




###############################################################################
# screening for the closest strain (time consuming process)
    echo "Do you want to find the closest genome in NCBI? yes or PRESS enter to skip the screening"
    read answer

    if [ "$answer" == "yes" ] ; then
    for F1 in $(cat $list);do
    echo screening "$F1"
    (mash screen -w -p 8 /home/swapnil/pipeline/tools/databases/mash/refseq.genomes.k21s1000.msh $wd/fasta/"$F1".fasta > $wd/tmp/"$F1".screen.tmp)> /dev/null 2>&1
    sort -gr $wd/tmp/"$F1".screen.tmp | head > $wd/results/"$F1".screen.tab
    sed -i 's/^/'"$F1"'	/' $wd/results/"$F1".screen.tab
    (mash screen -w -p 8 /home/swapnil/pipeline/tools/databases/mash/refseq.plasmid.k21s1000.msh $wd/fasta/"$F1".fasta > $wd/tmp/"$F1".screen.plasmid.tmp)> /dev/null 2>&1
    sort -gr $wd/tmp/"$F1".screen.plasmid.tmp | head > $wd/results/"$F1".screen.plasmid.tab
    sed -i 's/^/'"$F1"'	/' $wd/results/"$F1".screen.plasmid.tab
    done
    #------
    cat $wd/results/*.screen.tab > $wd/results/all.screen.tab

    if grep -Fxq  "Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment" $wd/results/all.screen.tab; then
    :
    else
    ex -sc '1i|Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment' -cx $wd/results/all.screen.tab
    fi

    unoconv -i FilterOptions=09,,system,1 -f xls -o $wd/all.screen.xls $wd/results/all.screen.tab 

    #------

    cat $wd/results/*.screen.plasmid.tab > $wd/results/all.screen.plasmid.tab

    if grep -Fxq  "Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment" $wd/results/all.screen.plasmid.tab; then
    :
    else
    ex -sc '1i|Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment' -cx $wd/results/all.screen.plasmid.tab
    fi

    unoconv -i FilterOptions=09,,system,1 -f xls -o $wd/all.screen.plasmid.xls $wd/results/all.screen.plasmid.tab 

    fi
###############################################################################
echo "script 0137_phylongey_ANI_by_mash ended ----------------------------------------"
###############################################################################
