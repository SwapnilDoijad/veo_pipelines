#!/bin/bash
echo "Hi Swapnil, transpose step needs higher memory, runs well on log-in node but doesnt run on working node"
###############################################################################
echo "script 0331_ANI_by_minhash started --------------------------------------"
###############################################################################
## step-01: file and directory preparatoins
    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "-------------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g'
        echo "-------------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi
    #------------------------------------------------------------------------------

    (mkdir -p results/0331_ANI_by_minhash/tmp)> /dev/null 2>&1
    (mkdir -p results/0331_ANI_by_minhash/msh/distance)> /dev/null 2>&1
    (mkdir -p results/0331_ANI_by_minhash/msh/distance/tmp)> /dev/null 2>&1

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate R

    # Specify the number of CPU cores you want to use
    num_cores=80

    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep -w "^fasta" result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi

###############################################################################
## step-02: copying files
    if [ ! -f results/0331_ANI_by_minhash/msh/mash_sketch.msh ] ; then 
    if [ ! -d results/0331_ANI_by_minhash/fasta ] ; then 
        echo "copying files"

        (mkdir -p results/0331_ANI_by_minhash/fasta )> /dev/null 2>&1


        # Split the input list into chunks and store them in temporary files
        split -n l/${num_cores} -d $list temp_list_

        # Define a function to process a chunk of the input list
        process_chunk() {
            local input_list="$1"
            local fasta_path="$2"
            while read -r F1; do
                cp $fasta_path/"$F1".fasta results/0331_ANI_by_minhash/fasta/"$F1".fasta
            done < "$input_list"
        }

        # Use GNU Parallel to process the chunks in parallel
        export -f process_chunk
        /home/groups/VEO/tools/parallel/v20230822/src/parallel -j ${num_cores} process_chunk ::: temp_list_* ::: "$fasta_file_path"

        # Remove temporary files
        rm temp_list_*

        echo "copying files: finished"
        else    
        echo "Copying files already finished"
    fi
    fi

###############################################################################
## step-03: sketching
    if [ ! -f results/0331_ANI_by_minhash/msh/mash_sketch.msh ] ; then 
        echo "sketching"
        (/home/groups/VEO/tools/mash/v2.3/mash sketch -p 80 -o results/0331_ANI_by_minhash/msh/mash_sketch.msh results/0331_ANI_by_minhash/fasta/*.fasta)> /dev/null 2>&1
        echo "sketching: finished"
        else
        echo "sketching already finished"
    fi 
    # (rm -rf results/0331_ANI_by_minhash/fasta)> /dev/null 2>&1

###############################################################################
## step-04: mashing
    if [ ! -f results/0331_ANI_by_minhash/tmp/all.distance.for_R.tab ] ; then 
        echo "mashing"
        /home/groups/VEO/tools/mash/v2.3/mash triangle -p 80 results/0331_ANI_by_minhash/msh/mash_sketch.msh > results/0331_ANI_by_minhash/tmp/all.distance.for_R.tab
        echo "mashing: finished"
        else 
        echo "mashing already finished"
    fi
###############################################################################
## step-05: post-calculations 
    echo "running post-calculations"

    # cat results/0331_ANI_by_minhash/tmp/all.distance.for_R.tab | sed 's/results\/0331_ANI_by_minhash\/fasta\///g' | sed '1d'  > results/0331_ANI_by_minhash/tmp/all.distance.for_R.2.tab
    # python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/transpose_lower_triangle.py -i results/0331_ANI_by_minhash/tmp/all.distance.for_R.2.tab -o results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.2.tab
    
    cat results/0331_ANI_by_minhash/tmp/all.distance.for_R.tab | sed '1d' | sed 's/\.fasta//g' > results/0331_ANI_by_minhash/tmp/all.distance.for_R.out.tab
    cat results/0331_ANI_by_minhash/tmp/all.distance.for_R.out.tab | sed 's/results\/0331_ANI_by_minhash\/fasta\///g' > results/0331_ANI_by_minhash/tmp/all.distance.for_R.out.2.tab
    
    cp results/0331_ANI_by_minhash/tmp/all.distance.for_R.out.2.tab results/out.tab
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/transpose.mash.sh
    mv results/out.t.tab results/0331_ANI_by_minhash/tmp/all.distance.for_R.out.t.tab
    awk 'NR==FNR{ a[NR+1]=$0 FS 0; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' results/0331_ANI_by_minhash/tmp/all.distance.for_R.out.2.tab results/0331_ANI_by_minhash/tmp/all.distance.for_R.out.t.tab > results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.tab
    sed -i 's/ /\t/g' results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.tab
    sed -e "1,/0/s/0//" results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.tab > results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.2.tab

    R1_rows=$(wc -l results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.2.tab | awk '{print $1}' )
    R2_columns=$(head -n1 results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.2.tab |  sed 's/\t/\n/g' | wc -l)
    echo "rows:$R1_rows columns:$R2_columns"

    #------------------------------------------------------------------------------
    # for_R
    if [ ! "$R1_rows" == "$R2_columns" ] ; then
        echo "rows and cloumns numbers are not OK for R, could not run plot_and_tree.mash-distance.r"
        else
        echo "running R"
        cp results/0331_ANI_by_minhash/tmp/all.distance.for_R.matrix.2.tab results/all.distance.for_R.matrix.2.tab
        Rscript /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/plot_and_tree.mash-distance.r
        sed -i "s/minhash/minhash/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/plot_and_tree.mash-distance.r
        # rm results/all.distance.for_R.matrix.2.tab
        (mv Rplots.pdf results/0331_ANI_by_minhash/)> /dev/null 2>&1
        (mv tree.nwk results/0331_ANI_by_minhash/)> /dev/null 2>&1
    fi

    echo "post-calculations finished"

exit
###############################################################################
## Mash with GGRaSP package 
    echo "running GGRaSP package"
    for F1 in $(cat $list); do
    F2=$(echo $F1 | awk -F'.' '{print $1}')
    awk -F'\t' -v col="$F2" 'NR==1{for(i=1;i<=NF;i++){if($i==col){c=i;break}} print $c} NR>1{print (1-$c)*100}' results/0331_ANI_by_minhash/tmp/all.distance.for_R.tab > results/0331_ANI_by_minhash/msh/distance/tmp/$F1.ggrasp.tmp
    done
    ## get first-name column
    awk -F'\t' '{print $1}' results/0331_ANI_by_minhash/tmp/all.distance.for_R.tab | sed '1d' > results/0331_ANI_by_minhash/tmp/list.ggrasp

    cat results/0331_ANI_by_minhash/tmp/list.ggrasp | sed '1i\\' > results/0331_ANI_by_minhash/msh/distance/all.ggrasp.tab
    for F1 in $(cat results/0331_ANI_by_minhash/tmp/list.ggrasp); do
    paste results/0331_ANI_by_minhash/msh/distance/all.ggrasp.tab results/0331_ANI_by_minhash/msh/distance/tmp/$F1.ggrasp.tmp > results/0331_ANI_by_minhash/msh/distance/all.ggrasp.tab.tmp
    mv results/0331_ANI_by_minhash/msh/distance/all.ggrasp.tab.tmp results/0331_ANI_by_minhash/msh/distance/all.ggrasp.tab
    done

    mv results/0331_ANI_by_minhash/msh/distance/all.ggrasp.tab results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab
    #------------------------------------------------------------------------------
    G1_rows=$(wc -l results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab | awk '{print $1}' )
    G2_columns=$(head -n1 results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab |  sed 's/\t/\n/g' | wc -l)
    echo "$G1_rows $G2_columns "
    #------------------------------------------------------------------------------
    # for_GGRaSP get a representative of a clutster at 95% (-h 5)
    if [ ! "$G1_rows" == "$G2_columns" ] ; then
    echo "rows and cloumns numbers are not OK for GGRaSP, could not run all.distance.for_GGRaSP.tab"
    else
    echo "running ggrasp.R"
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab -d 100 -h 5.0000 -o results/0331_ANI_by_minhash/representative_of_a_clusters_at_95.0000_250000nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0100 -o results/0331_ANI_by_minhash/representative_of_a_clusters_at_99.9900_000500nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0050 -o results/0331_ANI_by_minhash/representative_of_a_clusters_at_99.9950_000250nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0010 -o results/0331_ANI_by_minhash/representative_of_a_clusters_at_99.9990_000050nucl-5Mb-genome_ANI )> /dev/null 2>&1
    (/home/swapnil/tools/GGRaSP-master/ggrasp.R -i results/0331_ANI_by_minhash/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0001 -o results/0331_ANI_by_minhash/representative_of_a_clusters_at_99.9999_000005nucl-5Mb-genome_ANI )> /dev/null 2>&1
    fi
    
    #----------------------------------------------------------------------------
    ## for 
        ls results/0331_ANI_by_minhash//*.medoids.txt | awk -F'/' '{print $NF}' > results/0331_ANI_by_minhash/tmp/list.ggrasp.tmp
            for F3 in $(cat results/0331_ANI_by_minhash/tmp/list.ggrasp.tmp ); do
                echo "running mash and R for $F3"
                name=$( echo $F3 | awk -F'/' '{print $NF}' )
                mkdir results/0331_ANI_by_minhash/fasta_$F3
                for files in $(cat results/0331_ANI_by_minhash/$F3 ); do
                    cp results/0040_assembly/all_fasta/"$files".fasta results/0331_ANI_by_minhash/fasta_$F3/
                done
                #echo "sketching"
                (mash sketch -o results/0331_ANI_by_minhash/msh/mash_sketch.$name.msh results/0331_ANI_by_minhash/fasta_$F3/*.fasta)> /dev/null 2>&1
                rm -rf results/0331_ANI_by_minhash/fasta_$F3
                #echo "mashing"
                mash dist results/0331_ANI_by_minhash/msh/mash_sketch.$name.msh results/0331_ANI_by_minhash/msh/mash_sketch.$name.msh | square_mash > results/0331_ANI_by_minhash/tmp/all.distance.for_R.$name.tab

                #------------------------------------------------------------------------------
                # for_R
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.tab/all.distance.for_R.$name.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                Rscript /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.$name.tab/all.distance.for_R.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                (mv Rplots.pdf results/0331_ANI_by_minhash/$name.Rplots.pdf)> /dev/null 2>&1
                (mv tree.nwk results/0331_ANI_by_minhash/$name.tree.nwk)> /dev/null 2>&1
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
    (mash screen -w -p 8 /home/swapnil/pipeline/tools/databases/mash/refseq.genomes.k21s1000.msh results/0331_ANI_by_minhash/fasta/"$F1".fasta > results/0331_ANI_by_minhash/tmp/"$F1".screen.tmp)> /dev/null 2>&1
    sort -gr results/0331_ANI_by_minhash/tmp/"$F1".screen.tmp | head > results/0331_ANI_by_minhash/results/"$F1".screen.tab
    sed -i 's/^/'"$F1"'	/' results/0331_ANI_by_minhash/results/"$F1".screen.tab
    (mash screen -w -p 8 /home/swapnil/pipeline/tools/databases/mash/refseq.plasmid.k21s1000.msh results/0331_ANI_by_minhash/fasta/"$F1".fasta > results/0331_ANI_by_minhash/tmp/"$F1".screen.plasmid.tmp)> /dev/null 2>&1
    sort -gr results/0331_ANI_by_minhash/tmp/"$F1".screen.plasmid.tmp | head > results/0331_ANI_by_minhash/results/"$F1".screen.plasmid.tab
    sed -i 's/^/'"$F1"'	/' results/0331_ANI_by_minhash/results/"$F1".screen.plasmid.tab
    done
    #------
    cat results/0331_ANI_by_minhash/results/*.screen.tab > results/0331_ANI_by_minhash/results/all.screen.tab

    if grep -Fxq  "Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment" results/0331_ANI_by_minhash/results/all.screen.tab; then
    :
    else
    ex -sc '1i|Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment' -cx results/0331_ANI_by_minhash/results/all.screen.tab
    fi

    unoconv -i FilterOptions=09,,system,1 -f xls -o results/0331_ANI_by_minhash/all.screen.xls results/0331_ANI_by_minhash/results/all.screen.tab 

    #------

    cat results/0331_ANI_by_minhash/results/*.screen.plasmid.tab > results/0331_ANI_by_minhash/results/all.screen.plasmid.tab

    if grep -Fxq  "Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment" results/0331_ANI_by_minhash/results/all.screen.plasmid.tab; then
    :
    else
    ex -sc '1i|Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment' -cx results/0331_ANI_by_minhash/results/all.screen.plasmid.tab
    fi

    unoconv -i FilterOptions=09,,system,1 -f xls -o results/0331_ANI_by_minhash/all.screen.plasmid.xls results/0331_ANI_by_minhash/results/all.screen.plasmid.tab 

    fi
###############################################################################
echo "script 0331_ANI_by_minhash ended ----------------------------------------"
###############################################################################
