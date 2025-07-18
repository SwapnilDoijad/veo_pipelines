#!/bin/bash
#SBATCH --job-name=0132_phylogeny_for_phage_by_shared_genome_content
#SBATCH --partition=interactive,standard,long
#SBATCH --output=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.out
#SBATCH --error=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
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
        cat $list > $raw_files/SGC_ANI/ANI.txt
        for i in $(cat $list); do 
            paste \
            $raw_files/SGC_ANI/SGC_ANI.txt \
            $raw_files/SGC_ANI/tmp/$i.txt \
            > $raw_files/SGC_ANI/SGC_ANI.tmp

            paste \
            $raw_files/SGC_ANI/ANI.txt \
            $raw_files/SGC_ANI/tmp/$i.ANI.txt \
            > $raw_files/SGC_ANI/ANI.tmp

            mv $raw_files/SGC_ANI/SGC_ANI.tmp $raw_files/SGC_ANI/SGC_ANI.txt
            mv $raw_files/SGC_ANI/ANI.tmp $raw_files/SGC_ANI/ANI.txt
        done 

        cat $list | tr '\n' '\t' > $raw_files/header.tmp
        sed -i '1s/^/\t/' $raw_files/header.tmp
        sed -i -e '$a\' $raw_files/header.tmp

        cat $raw_files/header.tmp $raw_files/SGC_ANI/SGC_ANI.txt > $raw_files/all.SGC_ANI.tmp
        cat $raw_files/header.tmp $raw_files/SGC_ANI/ANI.txt > $raw_files/all.ANI.tmp
        sed -i 's/ /\t/g' $raw_files/all.SGC_ANI.tmp
        sed -i 's/ /\t/g' $raw_files/all.ANI.tmp

        mv $raw_files/all.SGC_ANI.tmp $raw_files/SGC_ANI.tab
        mv $raw_files/all.ANI.tmp $raw_files/ANI.tab
        rm $raw_files/*.tmp
    fi
###############################################################################
## run GGRaSP package that create tree

    ## 2025-06-20 10:38:30
        ## phylogeny may not be a good idea for unrelated genomes
        ## rather, clustering methods (for e.g. PCA and heatmap) is more logical
        ## -h 0.0001 doesnt matter for phylogeny

    if [ ! -f $raw_files/SGC_ANI.tab.ggrasp.tree.nwk ]; then
        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
        conda activate R

        G1_rows=$(wc -l $raw_files/SGC_ANI.tab | awk '{print $1}' )
        G2_columns=$(head -n1 $raw_files/SGC_ANI.tab | sed ' s/\t/\n/g' | sed '${/^$/d;}' | wc -l)
        echo "$G1_rows $G2_columns " 
        if [ "$G1_rows" == "$G2_columns" ] ; then
            log "step-7: running GGRaSP"
            ( $ggrasp_tool_path/ggrasp.R \
            -i $raw_files/SGC_ANI.tab \
            -d 100 -h 0.0001 \
            -o $raw_files/SGC_ANI.tab.ggrasp.tree.nwk )> /dev/null 2>&1

            ( $ggrasp_tool_path/ggrasp.R \
            -i $raw_files/ANI.tab \
            -d 100 -h 0.0001 \
            -o $raw_files/ANI.tab.ggrasp.tree.nwk )> /dev/null 2>&1

        fi

        (rm *.tmp )> /dev/null 2>&1
        (rm $raw_files/tmp/*.tmp )> /dev/null 2>&1
    fi
###############################################################################
## Phylogeny with r package

    ## 2025-06-20 10:38:30
        ## phylogeny may not be a good idea for unrelated genomes
        ## rather, clustering methods (for e.g. PCA and heatmap) is more logical

    if [ ! -f $raw_files/ANI.tab.UPGMA.nwk] ; then 
        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
        conda activate R

        G1_rows=$(wc -l $raw_files/SGC_ANI.tab | awk '{print $1}' )
        G2_columns=$(head -n1 $raw_files/SGC_ANI.tab | sed ' s/\t/\n/g' | sed '${/^$/d;}' | wc -l)
        log "$G1_rows $G2_columns " 
        if [ "$G1_rows" == "$G2_columns" ] ; then
            log "step-7: running GGRaSP"
            Rscript $utilities/plot_and_tree.fastANI-distance.r \
            -i $raw_files/SGC_ANI.tab \
            -o $raw_files/SGC_ANI.tab.UPGMA.nwk

            Rscript $utilities/plot_and_tree.fastANI-distance.r \
            -i $raw_files/ANI.tab \
            -o $raw_files/ANI.tab.UPGMA.nwk

        fi
    fi
###############################################################################
## phylogeny with ete3 kit
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    conda activate ete3_v3.1.3
    ## needed for ete3 kit for pdf rendering
    export QT_QPA_PLATFORM=offscreen 

    if [ ! -f $raw_files/plots/SGC_ANI.tab.ggrasp.tree.nwk.pdf ]; then
        log "step-8: rendering trees with ete3"

        python $utilities/render_tree.py \
        -i $raw_files/SGC_ANI.tab.ggrasp.tree.nwk \
        -o $raw_files/plots/SGC_ANI.tab.ggrasp.tree.nwk.pdf


        python $utilities/render_tree.py \
        -i $raw_files/ANI.tab.ggrasp.tree.nwk \
        -o $raw_files/plots/ANI.tab.ggrasp.tree.nwk.pdf


        python $utilities/render_tree.py \
        -i $raw_files/SGC_ANI.tab.UPGMA.nwk \
        -o $raw_files/plots/SGC_ANI.tab.UPGMA.nwk.pdf


        python $utilities/render_tree.py \
        -i $raw_files/ANI.tab.UPGMA.nwk \
        -o $raw_files/plots/ANI.tab.UPGMA.nwk.pdf

        else
        log "ALREADY FINISHED: rendering trees with ete3"
    fi

###############################################################################
## clustering
    if [ ! -f $raw_files/plots/SGC_ANI.tab.heatmap.pdf ]; then
        source /home/groups/VEO/tools/biopython/myenv/bin/activate
            python $utilities/heatmap_cluster.py \
            -i $raw_files/SGC_ANI.tab \
            -o $raw_files/plots/SGC_ANI.tab.heatmap.pdf

            python $utilities/pca_cluster.py \
            -i $raw_files/SGC_ANI.tab \
            -o $raw_files/plots/SGC_ANI.tab.pca.pdf

            python $utilities/heatmap_cluster.py \
            -i $raw_files/ANI.tab \
            -o $raw_files/plots/ANI.tab.heatmap.pdf

            python $utilities/pca_cluster.py \
            -i $raw_files/ANI.tab \
            -o $raw_files/plots/ANI.tab.pca.pdf

        deactivate
    fi
###############################################################################
## report
    pdfunite \
    $raw_files/plots/SGC_ANI.tab.heatmap.pdf \
    $raw_files/plots/SGC_ANI.tab.pca.pdf \
    $raw_files/plots/SGC_ANI.tab.UPGMA.nwk.pdf \
    $raw_files/plots/ANI.tab.heatmap.pdf \
    $raw_files/plots/ANI.tab.pca.pdf \
    $raw_files/plots/ANI.tab.UPGMA.nwk.pdf \
    $raw_files/report.pdf
###############################################################################
## discarded codes
        # ls $raw_files//*.medoids.txt | awk -F'/' '{print $NF}' > $raw_files/tmp/list.ggrasp.tmp
        #     for F3 in $(cat $raw_files/tmp/list.ggrasp.tmp ); do
        #         echo "running mash and R for $F3"
        #         name=$( echo $F3 | awk -F'/' '{print $NF}' )
        #         mkdir $raw_files/fasta_$F3
        #         for files in $(cat $raw_files/$F3 ); do
        #             cp $fasta_file_path/"$files".fasta $raw_files/fasta_$F3/
        #         done
        #         #echo "sketching"
        #         (mash sketch -o $raw_files/msh/mash_sketch.$name.msh $raw_files/fasta_$F3/*.fasta)> /dev/null 2>&1
        #         rm -rf $raw_files/fasta_$F3
        #         #echo "mashing"
        #         mash dist $raw_files/msh/mash_sketch.$name.msh $raw_files/msh/mash_sketch.$name.msh | square_mash > $raw_files/tmp/all.distance.for_R.$name.tab

        #         #------------------------------------------------------------------------------
        #         # for_R
        #         sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
        #         sed -i "s/all.distance.for_R.tab/all.distance.for_R.$name.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
        #         Rscript /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
        #         sed -i "s/minhash/minhash/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
        #         sed -i "s/all.distance.for_R.$name.tab/all.distance.for_R.tab/g" /home/swapnil/pipeline/tools/plot_and_tree.mash-distance.r
        #         (mv Rplots.pdf $raw_files/$name.Rplots.pdf)> /dev/null 2>&1
        #         (mv tree.nwk $raw_files/$name.tree.nwk)> /dev/null 2>&1
        #     done
##############################################################################
