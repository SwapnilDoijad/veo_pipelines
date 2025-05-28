#!/bin/bash
#SBATCH --job-name=0137_phylogeny_ANI_by_mash
#SBATCH --partition=interactive,short,long
#SBATCH --output=results/0137_phylogeny_ANI_by_mash/tmp/slurm/%j.out
#SBATCH --error=results/0137_phylogeny_ANI_by_mash/tmp/slurm/%j.err
#SBATCH --cpus-per-task=20
#SBATCH --mem=200G
#SBATCH --mail-type=END
#SBATCH --mail-user=your_email@example.com
###############################################################################  
## header
    pipeline=0137_phylogeny_ANI_by_mash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline started --------------------------------------"
############################################################################### 
## 00 preparations 
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    pair_wise_distance=$( grep my_pair_wise_distance $parameters | awk '{print $2}' )

    log "fasta_directory: $fasta_directory"
    log "pair_wise_distance: $pair_wise_distance"
############################################################################### 
## step-00: check if the fasta files are OK

    if [ ! -f $wd/fasta_error.txt ] ; then 
        grep -L "^>" $fasta_directory/*.*  > $wd/fasta_error.txt
    fi

    if [ -f $wd/fasta_error.txt ] ; then 
        for fasta_with_error in $(cat $wd/fasta_error.txt); do
            rm -rf $fasta_with_error
        done
    fi

############################################################################### 
## step-01: sketching
    if [ ! -f $raw_files/msh/mash_sketch.msh ] ; then 
        log "STARTED : $pipeline : sketching"
            /home/groups/VEO/tools/mash/v2.3/mash sketch \
            -p $SLURM_CPUS_PER_TASK \
            -s 1000 \
            -o $raw_files/msh/mash_sketch.msh \
            $fasta_directory/*.* #)> /dev/null 2>&1
        log "FINISHED: $pipeline : sketching"
        else
        log "ALREADY FINISHED : $pipeline : sketching"
    fi 
## step-02: mashing
    if [ ! -f $raw_files/tmp/all.distance.for_R.tab ] ; then 
        log "STARTED : $pipeline : mashing"

        /home/groups/VEO/tools/mash/v2.3/mash triangle \
        -p $SLURM_CPUS_PER_TASK \
        $raw_files/msh/mash_sketch.msh \
        > $raw_files/tmp/all.distance.for_R.tab

        log "FINISHED: $pipeline : mashing"
        else 
        log "ALREADY FINISHED : $pipeline : mashing"
    fi

###############################################################################
## pair-wise-distance
    if [ "$pair_wise_distance" == "Yes" ] ; then 
    if [ ! -f $wd/distance.matrix.tsv ] ; then
        log "STARTED : $pipeline : pair-wise-distance"

        for i in $( ls $fasta_directory ); do 
            if [ ! -f $raw_files/msh/$i.msh ] ; then
                /home/groups/VEO/tools/mash/v2.3/mash sketch \
                -p $SLURM_CPUS_PER_TASK \
                -s 10000 \
                -o $raw_files/msh/$i.msh \
                $fasta_directory/$i
            fi
        done

        if [ ! -f $raw_files/distance.tmp ] ; then 
            for i1 in $( ls $fasta_directory ); do 
                for i2 in $( ls $fasta_directory ); do 
                    /home/groups/VEO/tools/mash/v2.3/mash dist \
                    $raw_files/msh/$i1.msh \
                    $raw_files/msh/$i2.msh \
                    >> $raw_files/distance.tmp
                done 
            done
        fi

        sed -i "s|$fasta_directory/||g" $raw_files/distance.tmp
        sed -i "s|\.fasta||g" $raw_files/distance.tmp
        awk '{print (1-$3)*100}' $raw_files/distance.tmp > $raw_files/ANI.tmp
        paste $raw_files/distance.tmp $raw_files/ANI.tmp > $raw_files/distance.tsv

        source /home/groups/VEO/tools/biopython/myenv/bin/activate
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/matrix.py \
        -i $raw_files/distance.tsv \
        -o $wd/distance.matrix.tsv \
        -c 6
        deactivate

        rm -rf $raw_files/ANI.tmp
        rm -rf $raw_files/distance.tmp
    fi
    fi
###############################################################################
## step-05: post-calculations 
    log "STARTED : $pipeline :  running post-calculations"

    if [ ! -f $raw_files/tmp/all.distance.for_R.matrix.tab ] ; then   
        cat $raw_files/tmp/all.distance.for_R.tab | sed '1d' | sed 's/\.fasta//g' > $raw_files/tmp/all.distance.for_R.out.tab
        cat $raw_files/tmp/all.distance.for_R.out.tab | sed "s|$fasta_directory/||g" > $raw_files/tmp/all.distance.for_R.out.2.tab
        
        cp $raw_files/tmp/all.distance.for_R.out.2.tab $wd/out.tab
        bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/transpose.mash.sh # out: results/0137_phylogeny_ANI_by_mash/out.t.tab
        #  python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/transpose_lower_triangle_by_itertools.py
        mv $wd/out.t.tab $raw_files/tmp/all.distance.for_R.out.t.tab

        awk 'NR==FNR{ a[NR+1]=$0 FS 0; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' \
        $raw_files/tmp/all.distance.for_R.out.2.tab \
        $raw_files/tmp/all.distance.for_R.out.t.tab \
        > $raw_files/tmp/all.distance.for_R.matrix.tab

        sed -i 's/ /\t/g' $raw_files/tmp/all.distance.for_R.matrix.tab
        # sed -e "1,/0/s/0//" $raw_files/tmp/all.distance.for_R.matrix.tab > $raw_files/tmp/all.distance.for_R.matrix.tab
    fi
        R1_rows=$(wc -l $raw_files/tmp/all.distance.for_R.matrix.tab | awk '{print $1}' )
        R2_columns=$(head -1 $raw_files/tmp/all.distance.for_R.matrix.tab |  sed 's/\t/\n/g' | wc -l ) 
        echo "rows:$R1_rows columns:$R2_columns"
    #------------------------------------------------------------------------------
    # for_R
    if [ ! "$R1_rows" == "$R2_columns" ] ; then
        log "rows and cloumns numbers are not OK for R, could not run plot_and_tree.mash-distance.r"
        else
        log "running R"
        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate R
        cp $raw_files/tmp/all.distance.for_R.matrix.tab $raw_files/matrix.tab
        Rscript /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/plot_and_tree.mash-distance.r
    fi

    source /home/groups/VEO/tools/biopython/myenv/bin/activate 
        if [ ! -f $wd/matrix.tab.tree.phangorn.nwk.tip_labels ] ; then 
            python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/export_phylogenomic_tip_labels.py \
            -i $wd/matrix.tab.tree.phangorn.nwk \
            -o $wd/matrix.tab.tree.phangorn.nwk.tip_labels
        fi
    deactivate

    # rm -rf $raw_files/tmp 
    rm -rf $wd/out.tab
    echo "post-calculations finished"

###############################################################################
## GGRaSP
    log "CONVERTING: distance_to_ani"
    source /home/groups/VEO/tools/biopython/myenv/bin/activate
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/distance_to_ani.py \
        -i $raw_files/matrix.tab \
        -o $raw_files/matrix.ANI.tab
    deactivate
    log "CONVERTING: distance_to_ani finished"

    log "STARTED: GGRaSP representative calculations"
    source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate R_v4.4.2
    mkdir $raw_files/representatives > /dev/null 2>&1

    ## sometime 234.140 is read by r as 234.14 and thus it ends up finding duplicates or wrong values
    awk 'NR==1 {print; next} { $1 = "ID_" $1; print }' OFS='\t' $raw_files/matrix.ANI.tab > $raw_files/matrix.ANI.prefixed.tab

    (/home/groups/VEO/tools/ggrasp/v1.0/ggrasp.R  -i $raw_files/matrix.ANI.prefixed.tab --type matrix -d 100 -h 5.0000 -o $raw_files/representatives/representative_of_a_clusters_at_95.0000_250000nucl-5Mb-genome_ANI --plottree  --writetable 1 )> /dev/null 2>&1
    (/home/groups/VEO/tools/ggrasp/v1.0/ggrasp.R  -i $raw_files/matrix.ANI.prefixed.tab --type matrix -d 100 -h 0.0100 -o $raw_files/representatives/representative_of_a_clusters_at_99.9900_000500nucl-5Mb-genome_ANI --plottree )> /dev/null 2>&1
    (/home/groups/VEO/tools/ggrasp/v1.0/ggrasp.R  -i $raw_files/matrix.ANI.prefixed.tab --type matrix -d 100 -h 0.0050 -o $raw_files/representatives/representative_of_a_clusters_at_99.9950_000250nucl-5Mb-genome_ANI --plottree )> /dev/null 2>&1
    (/home/groups/VEO/tools/ggrasp/v1.0/ggrasp.R  -i $raw_files/matrix.ANI.prefixed.tab --type matrix -d 100 -h 0.0010 -o $raw_files/representatives/representative_of_a_clusters_at_99.9990_000050nucl-5Mb-genome_ANI --plottree )> /dev/null 2>&1
    (/home/groups/VEO/tools/ggrasp/v1.0/ggrasp.R  -i $raw_files/matrix.ANI.prefixed.tab --type matrix -d 100 -h 0.0001 -o $raw_files/representatives/representative_of_a_clusters_at_99.9999_000005nucl-5Mb-genome_ANI --plottree )> /dev/null 2>&1

    conda deactivate
    rm -rf $raw_files/matrix.ANI.prefixed.tab
    log "FINISHED: GGRaSP representative calculations"

exit 
###############################################################################
## 2025-05-27 16:30:40 @Swapnil Optional
    ## this will give you genomospecies
    python /home/groups/VEO/scripts_for_users/supplementary_scripts/0137_phylogeny_ANI_by_mash.py \
    -i $raw_files/representatives/representative_of_a_clusters_at_95.0000_250000nucl-5Mb-genome_ANI.table.txt \
    -o $raw_files/representatives/representative_of_a_clusters_at_95.0000_250000nucl-5Mb-genome_ANI.table.txt \
    -n Rhizobium 

###############################################################################
# screening for the closest strain (time consuming process)
    # echo "Do you want to find the closest genome in NCBI? yes or PRESS enter to skip the screening"
    # read answer

    # if [ "$answer" == "yes" ] ; then
    # for F1 in $(cat $list);do
    # echo screening "$F1"
    # (mash screen -w -p 8 /home/swapnil/pipeline/tools/databases/mash/refseq.genomes.k21s1000.msh $wd/fasta/"$F1".fasta > $wd/tmp/"$F1".screen.tmp)> /dev/null 2>&1
    # sort -gr $wd/tmp/"$F1".screen.tmp | head > $wd/results/"$F1".screen.tab
    # sed -i 's/^/'"$F1"'	/' $wd/results/"$F1".screen.tab
    # (mash screen -w -p 8 /home/swapnil/pipeline/tools/databases/mash/refseq.plasmid.k21s1000.msh $wd/fasta/"$F1".fasta > $wd/tmp/"$F1".screen.plasmid.tmp)> /dev/null 2>&1
    # sort -gr $wd/tmp/"$F1".screen.plasmid.tmp | head > $wd/results/"$F1".screen.plasmid.tab
    # sed -i 's/^/'"$F1"'	/' $wd/results/"$F1".screen.plasmid.tab
    # done
    # #------
    # cat $wd/results/*.screen.tab > $wd/results/all.screen.tab

    # if grep -Fxq  "Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment" $wd/results/all.screen.tab; then
    # :
    # else
    # ex -sc '1i|Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment' -cx $wd/results/all.screen.tab
    # fi

    # unoconv -i FilterOptions=09,,system,1 -f xls -o $wd/all.screen.xls $wd/results/all.screen.tab 

    # #------

    # cat $wd/results/*.screen.plasmid.tab > $wd/results/all.screen.plasmid.tab

    # if grep -Fxq  "Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment" $wd/results/all.screen.plasmid.tab; then
    # :
    # else
    # ex -sc '1i|Isolate-id	identity	shared-hashes	median-multiplicity	p-value	query-ID	query-comment' -cx $wd/results/all.screen.plasmid.tab
    # fi

    # unoconv -i FilterOptions=09,,system,1 -f xls -o $wd/all.screen.plasmid.xls $wd/results/all.screen.plasmid.tab 

    # fi
###############################################################################
echo "script 0137_phylogeny_ANI_by_mash ended ----------------------------------------"
###############################################################################
