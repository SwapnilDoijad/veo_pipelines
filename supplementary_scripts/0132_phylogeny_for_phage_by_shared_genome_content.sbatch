#!/bin/bash
#SBATCH --job-name=0132_phylogeny_for_phage_by_shared_genome_content
#SBATCH --partition=interactive,standard,long
#SBATCH --output=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.out
#SBATCH --error=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
###############################################################################  
## header
    pipeline=0132_phylogeny_for_phage_by_shared_genome_content
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    mash_tool_path=/home/groups/VEO/tools/mash/v2.3
    ggrasp_tool_path=/home/groups/VEO/tools/ggrasp/v1.0
    list=list.$pipeline.txt
    fasta_file_path=$(grep "my_fasta_path" $parameters | awk '{print $2}')

    log "STARTED : $pipeline started --------------------------------------"
    log "list: $list"
    log "fasta_file_path: $fasta_file_path"
############################################################################### 
## sketching
    if [ ! -d $raw_files/msh ]; then 
        mkdir $raw_files/msh
        for sublist in $(ls $wd/tmp/lists/ ); do 
            log "sketching $sublist"

            sed "s#ABC#$sublist#g" \
            "/home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sketch.sbatch" \
            > "$wd"/tmp/sbatch/"$pipeline.sketch.$sublist.sbatch"

            job_id=$(sbatch "$wd"/tmp/sbatch/"$pipeline.sketch.$sublist.sbatch" | awk '{print $4}')

            log "submitted sublist: $sublist with job_id: $job_id"
        done
    fi

   wait_till_all_job_finished_with_name 0132_s
############################################################################### 
## distance
    if [ ! -d $raw_files/distance ]; then 
        mkdir $raw_files/distance
        for sublist in $(ls $wd/tmp/lists/ ); do 
            log "distance $sublist"

            sed "s#ABC#$sublist#g" \
            "/home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.distance.sbatch" \
            > "$wd"/tmp/sbatch/"$pipeline.distance.$sublist.sbatch"

            job_id=$(sbatch "$wd"/tmp/sbatch/"$pipeline.distance.$sublist.sbatch" | awk '{print $4}')

            log "submitted sublist: $sublist with job_id: $job_id"
        done
    fi
    wait_till_all_job_finished_with_name 0132_d
############################################################################### 
## calculating SGC_ANI
    if [ ! -d $raw_files/SGC_ANI ] ; then
        log "calculating SGC_ANI"
        (mkdir $raw_files/SGC_ANI )> /dev/null 2>&1
        (mkdir $raw_files/SGC_ANI/tmp )> /dev/null 2>&1
        (rm $raw_files/tmp/SGC_ANI.txt)> /dev/null 2>&1

        for sublist in $(ls $wd/tmp/lists/ ); do 
            log "SGC $sublist"

            sed "s#ABC#$sublist#g" \
            "/home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.SGC.sbatch" \
            > "$wd"/tmp/sbatch/"$pipeline.SGC.$sublist.sbatch"

            job_id=$(sbatch "$wd"/tmp/sbatch/"$pipeline.SGC.$sublist.sbatch" | awk '{print $4}')

            log "submitted sublist: $sublist with job_id: $job_id"
        done

        else
        log "ALREADY FINISHED: calculating SGC_ANI"
    fi 
    wait_till_all_job_finished_with_name 0132_g

###############################################################################
## summarising results 
    if [ ! -f $raw_files/SGC_ANI.tab ] ; then
        cat $list > $raw_files/SGC_ANI/SGC_ANI.txt
        for i in $(cat $list); do 
            paste \
            $raw_files/SGC_ANI/SGC_ANI.txt \
            $raw_files/SGC_ANI/tmp/$i.txt \
            > $raw_files/SGC_ANI/SGC_ANI.tmp

            mv $raw_files/SGC_ANI/SGC_ANI.tmp $raw_files/SGC_ANI/SGC_ANI.txt
        done 

        cat $list | tr '\n' '\t' > $raw_files/header.tmp
        sed -i '1s/^/\t/' $raw_files/header.tmp
        sed -i -e '$a\' $raw_files/header.tmp
        cat $raw_files/header.tmp $raw_files/SGC_ANI/SGC_ANI.txt > $raw_files/all.SGC_ANI.tmp
        sed -i 's/ /\t/g' $raw_files/tmp/all.SGC_ANI.tmp
        mv $raw_files/all.SGC_ANI.tmp $raw_files/SGC_ANI.tab
        rm $raw_files/*.tmp
    fi
###############################################################################
## step-7: run GGRaSP package that create tree

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate R

    G1_rows=$(wc -l $raw_files/SGC_ANI.tab | awk '{print $1}' )
    G2_columns=$(head -n1 $raw_files/SGC_ANI.tab | sed ' s/\t/\n/g' | sed '${/^$/d;}' | wc -l)
    echo "$G1_rows $G2_columns " 
    if [ "$G1_rows" == "$G2_columns" ] ; then
        echo "step-7: running GGRaSP"
        #(
            $ggrasp_tool_path/ggrasp.R \
        -i $raw_files/SGC_ANI.tab \
        -d 100 -h 0.0001 \
        -o $raw_files/ggrasp.tree.nwk #)> /dev/null 2>&1
    fi

    (rm *.tmp )> /dev/null 2>&1
    (rm $raw_files/tmp/*.tmp )> /dev/null 2>&1

 exit
###############################################################################
## Phylogeny with r package
    if [ ! -f $raw_files/tree.nwk ] ; then 
        #------------------------------------------------------------------------------
        cat $raw_files/tmp/all.distance.for_R.tab | sed '1d' | sed 's/\.fasta//g' > $raw_files/tmp/all.distance.for_R.out.tab
        cat $raw_files/tmp/all.distance.for_R.out.tab | sed 's/results\/33_minhash_prophage_SGC_'$l'\/fasta\///g' > $raw_files/tmp/all.distance.for_R.out.2.tab
        cp $raw_files/tmp/all.distance.for_R.out.2.tab results/out.tab
        bash /home/groups/VEO/tools/suppl_scripts/transpose.mash.sh
        mv results/out.t.tab $raw_files/tmp/all.distance.for_R.out.t.tab
        awk 'NR==FNR{ a[NR+1]=$0 FS 0; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' $raw_files/tmp/all.distance.for_R.out.2.tab $raw_files/tmp/all.distance.for_R.out.t.tab > $raw_files/tmp/all.distance.for_R.matrix.tab
        sed -i 's/ /\t/g' $raw_files/tmp/all.distance.for_R.matrix.tab
        sed -e "0,/0/s/0//" $raw_files/tmp/all.distance.for_R.matrix.tab > $raw_files/tmp/all.distance.for_R.matrix.2.tab

        R1_rows=$(wc -l $raw_files/tmp/all.distance.for_R.matrix.2.tab | awk '{print $1}' )
        R2_columns=$(head -n1 $raw_files/tmp/all.distance.for_R.matrix.2.tab |  sed 's/\t/\n/g' | wc -l)
        echo "rows:$R1_rows columns:$R2_columns"
        #------------------------------------------------------------------------------
        # for_R
        if [ ! "$R1_rows" == "$R2_columns" ] ; then
            echo "rows and cloumns numbers are not OK for R, could not run plot_and_tree.mash-distance.r"
            else
            echo "running R"
            cp $raw_files/tmp/all.distance.for_R.matrix.2.tab results/all.distance.for_R.matrix.2.tab
            Rscript /home/groups/VEO/tools/suppl_scripts/plot_and_tree.mash-distance.r
            sed -i "s/minhash/minhash/g" /home/groups/VEO/tools/suppl_scripts/plot_and_tree.mash-distance.r
            rm results/all.distance.for_R.matrix.2.tab
            (mv Rplots.pdf $raw_files/)> /dev/null 2>&1
            (mv tree.nwk $raw_files/)> /dev/null 2>&1
        fi
    fi
###############################################################################
## GGRaSP package

    ##preparation for GGRaSP package
    if [ ! -f $raw_files/tmp/all.distance.for_GGRaSP.tab ] ; then  
        echo "running GGRaSP package"

        for F1 in $(cat $list); do
            awk -F'\t' -v col=$F1 'NR==1{for(i=1;i<=NF;i++){if($i==col){c=i;break}} print $c} NR>1{print (1-$c)*100}' $raw_files/tmp/all.distance.for_R.matrix.2.tab > $raw_files/msh/distance/tmp/$F1.ggrasp.tmp
        done
        ## get first-name column
        awk -F'\t' '{print $1}' $raw_files/tmp/all.distance.for_R.matrix.2.tab  > $raw_files/tmp/list.ggrasp
        awk -F'\t' 'NR>1 {print $1}' $raw_files/tmp/all.distance.for_R.matrix.2.tab > $raw_files/tmp/list.2.ggrasp
        #cat $raw_files/tmp/list.2.ggrasp | sed '1i\\' > $raw_files/msh/distance/all.ggrasp.tab
        cp $raw_files/tmp/list.ggrasp $raw_files/msh/distance/all.ggrasp.tab
        for F1 in $(cat $raw_files/tmp/list.2.ggrasp); do
            #echo $F1
            paste $raw_files/msh/distance/all.ggrasp.tab $raw_files/msh/distance/tmp/$F1.ggrasp.tmp > $raw_files/msh/distance/all.ggrasp.tab.tmp
            mv $raw_files/msh/distance/all.ggrasp.tab.tmp $raw_files/msh/distance/all.ggrasp.tab
        done
        mv $raw_files/msh/distance/all.ggrasp.tab $raw_files/tmp/all.distance.for_GGRaSP.tab
    
    fi
    #------------------------------------------------------------------------------
    G1_rows=$(wc -l $raw_files/tmp/all.distance.for_GGRaSP.tab | awk '{print $1}' )
    G2_columns=$(head -n1 $raw_files/tmp/all.distance.for_GGRaSP.tab |  sed 's/\t/\n/g' | wc -l)
    echo "$G1_rows $G2_columns "    

    #----------------------------------------------------------------------------
    # for_GGRaSP get a representative of a clutster at 95% (-h 5)
    if [ ! "$G1_rows" == "$G2_columns" ] ; then
        echo "rows and cloumns numbers are not OK for GGRaSP, could not run all.distance.for_GGRaSP.tab"
        else
        echo "running ggrasp.R"
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i $raw_files/tmp/all.distance.for_GGRaSP.tab -d 100 -h 5.0000 -o $raw_files/representative_of_a_clusters_at_95.0000_250000nucl-5Mb-genome_ANI )> /dev/null 2>&1
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i $raw_files/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0100 -o $raw_files/representative_of_a_clusters_at_99.9900_000500nucl-5Mb-genome_ANI )> /dev/null 2>&1
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i $raw_files/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0050 -o $raw_files/representative_of_a_clusters_at_99.9950_000250nucl-5Mb-genome_ANI )> /dev/null 2>&1
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i $raw_files/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0010 -o $raw_files/representative_of_a_clusters_at_99.9990_000050nucl-5Mb-genome_ANI )> /dev/null 2>&1
        /home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i $raw_files/tmp/all.distance.for_GGRaSP.tab -d 100 -h 0.0001 -o $raw_files/representative_of_a_clusters_at_99.9999_000005nucl-5Mb-genome_ANI #)> /dev/null 2>&1
        
        ## this is not working 
        #(/home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i $raw_files/tmp/all.distance.for_GGRaSP.tab -d 100 -o $raw_files/complete_clusters )> /dev/null 2>&1
    fi
###############################################################################
    exit



   /home/groups/VEO/tools/GGRaSP-master/ggrasp.R -i $raw_files/msh/distance/tmp/all.SGC_ANI.txt -d 100 -h 0.0001 -o $raw_files/tree.nwk
###############################################################################
## discarded codes
        ls $raw_files//*.medoids.txt | awk -F'/' '{print $NF}' > $raw_files/tmp/list.ggrasp.tmp
            for F3 in $(cat $raw_files/tmp/list.ggrasp.tmp ); do
                echo "running mash and R for $F3"
                name=$( echo $F3 | awk -F'/' '{print $NF}' )
                mkdir $raw_files/fasta_$F3
                for files in $(cat $raw_files/$F3 ); do
                    cp $fasta_file_path/"$files".fasta $raw_files/fasta_$F3/
                done
                #echo "sketching"
                (mash sketch -o $raw_files/msh/mash_sketch.$name.msh $raw_files/fasta_$F3/*.fasta)> /dev/null 2>&1
                rm -rf $raw_files/fasta_$F3
                #echo "mashing"
                mash dist $raw_files/msh/mash_sketch.$name.msh $raw_files/msh/mash_sketch.$name.msh | square_mash > $raw_files/tmp/all.distance.for_R.$name.tab

                #------------------------------------------------------------------------------
                # for_R
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.tab/all.distance.for_R.$name.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                Rscript /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                sed -i "s/all.distance.for_R.$name.tab/all.distance.for_R.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
                (mv Rplots.pdf $raw_files/$name.Rplots.pdf)> /dev/null 2>&1
                (mv tree.nwk $raw_files/$name.tree.nwk)> /dev/null 2>&1
            done
exit
##############################################################################
