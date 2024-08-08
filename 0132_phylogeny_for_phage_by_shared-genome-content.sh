#!/bin/bash
###############################################################################
#33 minhash prophage
###############################################################################
echo "started.... step-33 minhash prophage -----------------------------------"
###############################################################################
## file and directory preparations

        mash_tool_path=/home/groups/VEO/tools/mash/v2.3
        ggrasp_tool_path=/home/groups/VEO/tools/ggrasp/v1.0

        if [ -f list.prophage_fasta.txt ]; then 
            list=list.prophage_fasta.txt
            l=prophage_fasta
            elif [ -f list.bacterial_fasta.txt ] ; then 
            list=list.bacterial_fasta.txt
            l=bacterial_fasta
            else
            echo "provide genome list file (for e.g. all)"
            echo "-------------------------------------------------------------------------"
            ls list.*.txt | sed 's/ /\n/g'
            echo "-------------------------------------------------------------------------"
            read l
            list=$(echo "list.$l.txt")
        fi

    #------------------------------------------------------------------------------
    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep fasta result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi

    #------------------------------------------------------------------------------
    (mkdir -p results/33_minhash_prophage_SGC)> /dev/null 2>&1
    (mkdir -p results/33_minhash_prophage_SGC/tmp)> /dev/null 2>&1

    echo $l > original_list_name.tmp

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate R
###############################################################################
## running MASH
    if [ ! -f results/33_minhash_prophage_SGC/tmp/all.distance.for_R.tab ]; then

        ## step-1: copying fasta file
        if [ ! -d results/33_minhash_prophage_SGC/fasta ] ; then
            (mkdir results/33_minhash_prophage_SGC/fasta )> /dev/null 2>&1
            echo "step-1: copying fasta files"
            for F1 in $(cat $list); do
                if [ ! -f results/33_minhash_prophage_SGC/fasta/$F1.fasta ] ; then
                echo copying $F1.fasta
                    cp $fasta_file_path/"$F1".fasta results/33_minhash_prophage_SGC/fasta/$F1.fasta #)> /dev/null 2>&1
                fi 
            done
            else
            echo "ALREADY FINISHED step-1: copying fasta file"
        fi

        ## step-2: getting copied fasta
        ## sometime not all fasta are present, therfore create new list of copied fasta
        ls results/33_minhash_prophage_SGC/fasta | sed 's/\.fasta//g' > list."$l"_copied.txt
        list_copied_fasta=list."$l"_copied.txt
        
        ## step-3: sketching
        if [ ! -d results/33_minhash_prophage_SGC/msh ] ; then
            (mkdir results/33_minhash_prophage_SGC/msh)> /dev/null 2>&1
            echo "step-3: sketching"
            for i1 in $(cat $list_copied_fasta); do
                if [ ! -f results/33_minhash_prophage_SGC/msh/$i1.mash_sketch.msh ] ; then
                    $mash_tool_path/mash sketch -s 1000 -p 50 \
                    -o results/33_minhash_prophage_SGC/msh/$i1.mash_sketch.msh \
                    results/33_minhash_prophage_SGC/fasta/$i1.fasta #)> /dev/null 2>&1
                fi
            done
            #rm -rf results/33_minhash_prophage_SGC/fasta
            else
            echo "ALREADY FINISHED step-3: sketching" 
        fi

        ## step-4: calculating distance
        if [ ! -d results/33_minhash_prophage_SGC/distance ] ; then
            (mkdir results/33_minhash_prophage_SGC/distance )> /dev/null 2>&1
            (mkdir results/33_minhash_prophage_SGC/distance/list )> /dev/null 2>&1
            ## for more (>100) genomes, it takes long to get your results 
            ## therefore need to run this step parallely on cluster.
            echo "step-4: calculating distance: running through sbatch mode"
            split -d -l 100 list."$l"_copied.txt "$l"_copied_sublist
            ls "$l"_copied_sublist* > results/33_minhash_prophage_SGC/distance/list/list."$l"_copied_sublist.txt
            mv "$l"_copied_sublist* results/33_minhash_prophage_SGC/distance/list/

            (mkdir results/33_minhash_prophage_SGC/distance/sublist )> /dev/null 2>&1
            for my_fasta_prophage_copied_sublist in $(cat results/33_minhash_prophage_SGC/distance/list/list."$l"_copied_sublist.txt); do 
                sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/033c_mash_prophage_SGC_ANI.sbatch
                until test -d results/33_minhash_prophage_SGC/distance/sublist/"$my_fasta_prophage_copied_sublist" ; do
                    echo "waiting for results/33_minhash_prophage_SGC/distance/sublist/$my_fasta_prophage_copied_sublist"
                    sleep 5
                done
            done

            ## check if last file if completely processed 
            touch completely_processed.tmp
            for my_fasta_prophage_copied_sublist in $(cat results/33_minhash_prophage_SGC/distance/list/list."$l"_copied_sublist.txt) ; do
                while ! grep -q "finished $my_fasta_prophage_copied_sublist" completely_processed.tmp ; do
                    sleep 60
                    echo "waiting $my_fasta_prophage_copied_sublist to be completely processed"
                    cat slurm* | grep "finished $my_fasta_prophage_copied_sublist" > completely_processed.tmp
                done 
            done
            touch calculating_distance_finished.tmp
            (rm completely_processed.tmp) > /dev/null 2>&1

            ( mkdir results/33_minhash_prophage_SGC/distance/slurm_out )> /dev/null 2>&1
            mv slurm* results/33_minhash_prophage_SGC/distance/slurm_out

            ## slurm command ceates distance files in sublist directory
            ## for further calculations, need to move these files to a single directory 
            (mkdir results/33_minhash_prophage_SGC/distance/sublist/my_fasta_prophage_copied_all )> /dev/null 2>&1
            for my_fasta_prophage_copied_sublist in $(cat results/33_minhash_prophage_SGC/distance/list/list."$l"_copied_sublist.txt) ; do
                mv results/33_minhash_prophage_SGC/distance/sublist/$my_fasta_prophage_copied_sublist/*.txt results/33_minhash_prophage_SGC/distance/sublist/my_fasta_prophage_copied_all
            done
            else
            echo "ALREADY FINISHED step-4: calculating distance: running through sbatch mode"
        fi

        ## step-5: calculating SGC_ANI
        if [ ! -d results/33_minhash_prophage_SGC/SGC_ANI ] ; then
            echo "calculating SGC_ANI"
            (mkdir results/33_minhash_prophage_SGC/SGC_ANI )> /dev/null 2>&1
            (mkdir results/33_minhash_prophage_SGC/SGC_ANI/tmp )> /dev/null 2>&1
            (rm results/33_minhash_prophage_SGC/tmp/SGC_ANI.txt)> /dev/null 2>&1
            for i in $(cat $list_copied_fasta ); do
                echo "RUNNING step-5: calculating SGC_ANI $i "
                awk '{print $5}' results/33_minhash_prophage_SGC/distance/sublist/my_fasta_prophage_copied_all/$i.distance.txt | awk -F'/' '{print $1*100/1000 }' | tr ' ' '\n' > results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.SGC.txt
                awk '{print (1-$3)*100}' results/33_minhash_prophage_SGC/distance/sublist/my_fasta_prophage_copied_all/$i.distance.txt | tr ' ' '\n' > results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.ANI.txt
                paste results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.SGC.txt results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.ANI.txt > results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.SGC_ANI.txt
                awk '{print $1*$2/100}' results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.SGC_ANI.txt > results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.txt
            done
            else
            echo "ALREADY FINISHED step-5: calculating SGC_ANI"
        fi 

        ## step-6: summarising results 
        ## combine SGC_ANI values for all the genomes
        if [ ! -f results/33_minhash_prophage_SGC/SGC_ANI/SGC_ANI.txt ] ; then
            echo "STARTED step-6: summarising results"
            cat $list_copied_fasta > results/33_minhash_prophage_SGC/SGC_ANI/SGC_ANI.txt
            for i in $(cat $list_copied_fasta); do
            #echo $i
                paste results/33_minhash_prophage_SGC/SGC_ANI/SGC_ANI.txt results/33_minhash_prophage_SGC/SGC_ANI/tmp/$i.txt > results/33_minhash_prophage_SGC/SGC_ANI/SGC_ANI.tmp
                mv results/33_minhash_prophage_SGC/SGC_ANI/SGC_ANI.tmp results/33_minhash_prophage_SGC/SGC_ANI/SGC_ANI.txt
            done
            else
            echo "ALREADY FINISHED step-6: summarising results"
        fi


        if [ ! -f results/33_minhash_prophage_SGC/SGC_ANI.tab ]; then 
            cp results/33_minhash_prophage_SGC/SGC_ANI/SGC_ANI.txt results/33_minhash_prophage_SGC/tmp/all.SGC_ANI.txt
            ## sed command did now work for header becuase the header numbers are too many sed -i "1i $v1" results/33_minhash_prophage_SGC/all.SGC_ANI.txt
            ## So, writing header to file and using cat to combine header and result file
            cat $list_copied_fasta | tr '\n' '\t' > results/33_minhash_prophage_SGC/header.tmp
            sed -i '1s/^/\t/' results/33_minhash_prophage_SGC/header.tmp
            sed -i -e '$a\' results/33_minhash_prophage_SGC/header.tmp
            cat results/33_minhash_prophage_SGC/header.tmp results/33_minhash_prophage_SGC/tmp/all.SGC_ANI.txt > results/33_minhash_prophage_SGC/tmp/all.SGC_ANI.tmp
            sed -i 's/ /\t/g' results/33_minhash_prophage_SGC/tmp/all.SGC_ANI.tmp
            mv results/33_minhash_prophage_SGC/tmp/all.SGC_ANI.tmp results/33_minhash_prophage_SGC/SGC_ANI.tab
        fi

    fi

###############################################################################
## step-7: run GGRaSP package that create tree
    G1_rows=$(wc -l results/33_minhash_prophage_SGC/SGC_ANI.tab | awk '{print $1}' )
    G2_columns=$(head -n1 results/33_minhash_prophage_SGC/SGC_ANI.tab | sed ' s/\t/\n/g' | sed '${/^$/d;}' | wc -l)
    echo "$G1_rows $G2_columns " 
    if [ "$G1_rows" == "$G2_columns" ] ; then
        echo "step-7: running GGRaSP"
        #(
            $ggrasp_tool_path/ggrasp.R \
        -i results/33_minhash_prophage_SGC/SGC_ANI.tab \
        -d 100 -h 0.0001 \
        -o results/33_minhash_prophage_SGC/ggrasp."$l".tree.nwk #)> /dev/null 2>&1
    fi

    (rm *.tmp )> /dev/null 2>&1
    (rm results/33_minhash_prophage_SGC/tmp/*.tmp )> /dev/null 2>&1

 exit   
###############################################################################
## Phylogeny with r package
    if [ ! -f results/33_minhash_prophage_SGC/tree.nwk ] ; then 
        #------------------------------------------------------------------------------
        cat results/33_minhash_prophage_SGC/tmp/all.distance.for_R.tab | sed '1d' | sed 's/\.fasta//g' > results/33_minhash_prophage_SGC/tmp/all.distance.for_R.out.tab
        cat results/33_minhash_prophage_SGC/tmp/all.distance.for_R.out.tab | sed 's/results\/33_minhash_prophage_SGC_'$l'\/fasta\///g' > results/33_minhash_prophage_SGC/tmp/all.distance.for_R.out.2.tab
        cp results/33_minhash_prophage_SGC/tmp/all.distance.for_R.out.2.tab results/out.tab
        bash /home/groups/VEO/tools/suppl_scripts/transpose.mash.sh
        mv results/out.t.tab results/33_minhash_prophage_SGC/tmp/all.distance.for_R.out.t.tab
        awk 'NR==FNR{ a[NR+1]=$0 FS 0; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' results/33_minhash_prophage_SGC/tmp/all.distance.for_R.out.2.tab results/33_minhash_prophage_SGC/tmp/all.distance.for_R.out.t.tab > results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.tab
        sed -i 's/ /\t/g' results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.tab
        sed -e "0,/0/s/0//" results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.tab > results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.2.tab

        R1_rows=$(wc -l results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.2.tab | awk '{print $1}' )
        R2_columns=$(head -n1 results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.2.tab |  sed 's/\t/\n/g' | wc -l)
        echo "rows:$R1_rows columns:$R2_columns"
        #------------------------------------------------------------------------------
        # for_R
        if [ ! "$R1_rows" == "$R2_columns" ] ; then
            echo "rows and cloumns numbers are not OK for R, could not run plot_and_tree.mash-distance.r"
            else
            echo "running R"
            cp results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.2.tab results/all.distance.for_R.matrix.2.tab
            Rscript /home/groups/VEO/tools/suppl_scripts/plot_and_tree.mash-distance.r
            sed -i "s/minhash/minhash/g" /home/groups/VEO/tools/suppl_scripts/plot_and_tree.mash-distance.r
            rm results/all.distance.for_R.matrix.2.tab
            (mv Rplots.pdf results/33_minhash_prophage_SGC/)> /dev/null 2>&1
            (mv tree.nwk results/33_minhash_prophage_SGC/)> /dev/null 2>&1
        fi
    fi
###############################################################################
## GGRaSP package

    ##preparation for GGRaSP package
    if [ ! -f results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab ] ; then  
        echo "running GGRaSP package"

        for F1 in $(cat $list); do
            awk -F'\t' -v col=$F1 'NR==1{for(i=1;i<=NF;i++){if($i==col){c=i;break}} print $c} NR>1{print (1-$c)*100}' results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.2.tab > results/33_minhash_prophage_SGC/msh/distance/tmp/$F1.ggrasp.tmp
        done
        ## get first-name column
        awk -F'\t' '{print $1}' results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.2.tab  > results/33_minhash_prophage_SGC/tmp/list.ggrasp
        awk -F'\t' 'NR>1 {print $1}' results/33_minhash_prophage_SGC/tmp/all.distance.for_R.matrix.2.tab > results/33_minhash_prophage_SGC/tmp/list.2.ggrasp
        #cat results/33_minhash_prophage_SGC/tmp/list.2.ggrasp | sed '1i\\' > results/33_minhash_prophage_SGC/msh/distance/all.ggrasp.tab
        cp results/33_minhash_prophage_SGC/tmp/list.ggrasp results/33_minhash_prophage_SGC/msh/distance/all.ggrasp.tab
        for F1 in $(cat results/33_minhash_prophage_SGC/tmp/list.2.ggrasp); do
            #echo $F1
            paste results/33_minhash_prophage_SGC/msh/distance/all.ggrasp.tab results/33_minhash_prophage_SGC/msh/distance/tmp/$F1.ggrasp.tmp > results/33_minhash_prophage_SGC/msh/distance/all.ggrasp.tab.tmp
            mv results/33_minhash_prophage_SGC/msh/distance/all.ggrasp.tab.tmp results/33_minhash_prophage_SGC/msh/distance/all.ggrasp.tab
        done
        mv results/33_minhash_prophage_SGC/msh/distance/all.ggrasp.tab results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab
    
    fi
    #------------------------------------------------------------------------------
    G1_rows=$(wc -l results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab | awk '{print $1}' )
    G2_columns=$(head -n1 results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab |  sed 's/\t/\n/g' | wc -l)
    echo "$G1_rows $G2_columns "    

    #----------------------------------------------------------------------------
    # for_GGRaSP get a representative of a clutster at 95% (-h 5)
    if [ ! "$G1_rows" == "$G2_columns" ] ; then
        echo "rows and cloumns numbers are not OK for GGRaSP, could not run all.distance.for_GGRaSP.tab"
        else
        echo "running ggrasp.R"
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab -d 100 -h 5.0000 -o results/33_minhash_prophage_SGC/representative_of_a_clusters_at_95.0000_250000nucl-5Mb-genome_ANI )> /dev/null 2>&1
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0100 -o results/33_minhash_prophage_SGC/representative_of_a_clusters_at_99.9900_000500nucl-5Mb-genome_ANI )> /dev/null 2>&1
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0050 -o results/33_minhash_prophage_SGC/representative_of_a_clusters_at_99.9950_000250nucl-5Mb-genome_ANI )> /dev/null 2>&1
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0010 -o results/33_minhash_prophage_SGC/representative_of_a_clusters_at_99.9990_000050nucl-5Mb-genome_ANI )> /dev/null 2>&1
        /home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0001 -o results/33_minhash_prophage_SGC/representative_of_a_clusters_at_99.9999_000005nucl-5Mb-genome_ANI #)> /dev/null 2>&1
        
        ## this is not working 
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i results/33_minhash_prophage_SGC/tmp/all.distance.for_GGRaSP.tab -d 100 -o results/33_minhash_prophage_SGC/complete_clusters )> /dev/null 2>&1
    fi
###############################################################################
    exit



   /home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i results/33_minhash_prophage_SGC/msh/distance/tmp/all.SGC_ANI.txt -d 100 -h 0.0001 -o results/33_minhash_prophage_SGC/tree.nwk
###############################################################################
## discarded codes
        ls results/33_minhash_prophage_SGC//*.medoids.txt | awk -F'/' '{print $NF}' > results/33_minhash_prophage_SGC/tmp/list.ggrasp.tmp
            for F3 in $(cat results/33_minhash_prophage_SGC/tmp/list.ggrasp.tmp ); do
                echo "running mash and R for $F3"
                name=$( echo $F3 | awk -F'/' '{print $NF}' )
                mkdir results/33_minhash_prophage_SGC/fasta_$F3
                for files in $(cat results/33_minhash_prophage_SGC/$F3 ); do
                    cp $fasta_file_path/"$files".fasta results/33_minhash_prophage_SGC/fasta_$F3/
                done
                #echo "sketching"
                (mash sketch -o results/33_minhash_prophage_SGC/msh/mash_sketch.$name.msh results/33_minhash_prophage_SGC/fasta_$F3/*.fasta)> /dev/null 2>&1
                rm -rf results/33_minhash_prophage_SGC/fasta_$F3
                #echo "mashing"
                mash dist results/33_minhash_prophage_SGC/msh/mash_sketch.$name.msh results/33_minhash_prophage_SGC/msh/mash_sketch.$name.msh | square_mash > results/33_minhash_prophage_SGC/tmp/all.distance.for_R.$name.tab

                #------------------------------------------------------------------------------
                # for_R
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.tab/all.distance.for_R.$name.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                Rscript /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.$name.tab/all.distance.for_R.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                (mv Rplots.pdf results/33_minhash_prophage_SGC/$name.Rplots.pdf)> /dev/null 2>&1
                (mv tree.nwk results/33_minhash_prophage_SGC/$name.tree.nwk)> /dev/null 2>&1
            done
exit
##############################################################################
