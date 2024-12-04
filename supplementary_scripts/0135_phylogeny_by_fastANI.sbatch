#!/bin/bash
#SBATCH --job-name 0135_phylogeny_by_fastANI
#SBATCH --partition=gpu
#SBATCH --output results/0135_phylogeny_by_fastANI/tmp/slurm/%j.out
#SBATCH --error  results/0135_phylogeny_by_fastANI/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
#SBATCH --mail-type=END
#SBATCH --mail-user=your_email@example.com
###############################################################################
## step-01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0135_phylogeny_by_fastANI
    wd=results/$pipeline

    parameter_file=tmp/parameters/$pipeline.*
    fasta_path=$(grep my_fasta_path $parameter_file | awk '{print $2}')
    ls $fasta_path/*.fasta > $wd/tmp/list.fastANI.txt

###############################################################################
## step-02: run fastANI
    if [ ! -f $wd/raw_files/output.csv ] ; then 
        log "STARTED : $pipeline : fastANI run"

        /home/groups/VEO/tools/fastANI/v1.33/fastANI \
        --ql $wd/tmp/list.fastANI.txt \
        --rl $wd/tmp/list.fastANI.txt \
        -o $wd/raw_files/output.csv \
        --matrix \
        -t $SLURM_CPUS_PER_TASK 

        log "FINISHED : $pipeline : fastANI run"
        else 
        log "ALREADY FINISHED : $pipeline : fastANI run"
    fi

###############################################################################
## step-03: matrix-creation step

    log "fastANI finished, will create matrix and tree"

    sed -i -e 's/results\/0040_assembly\/all_fasta\///g' $wd/tmp/output.csv.matrix
    sed -i "s/\.fasta//g" $wd/tmp/output.csv.matrix

    sed -i "s/results\/0040_assembly\/all_fasta\///g" $wd/tmp/output.csv
    sed -i "s/\.fasta//g" $wd/tmp/output.csv

#------------------------------------------------------------------------------
## matrix-creation step
    cat $wd/tmp/output.csv.matrix | sed '1d' > $wd/tmp/all.distance.for_R.out.2.tab
    cp $wd/tmp/all.distance.for_R.out.2.tab results/out.tab
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/transpose.mash.sh
    mv results/out.t.tab $wd/tmp/all.distance.for_R.out.t.tab
    awk 'NR==FNR{ a[NR+1]=$0 FS 0; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' $wd/tmp/all.distance.for_R.out.2.tab $wd/tmp/all.distance.for_R.out.t.tab > $wd/tmp/all.distance.for_R.matrix.tab
    sed -i 's/ /\t/g' $wd/tmp/all.distance.for_R.matrix.tab
    sed -e "1,/0/s/0//" $wd/tmp/all.distance.for_R.matrix.tab > $wd/all.ANI.tab

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate R
    Rscript /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/plot_and_tree.fastANI-distance.r
    mv "Rplots.pdf" $wd/
    mv tree.nwk $wd/
###############################################################################
echo "completed.... step-41 pyANI --------------------------------------------"
###############################################################################
exit

#------------------------------------------------------------------------------
# get a representative of a clutster at 95% (-h 5)
echo "running ggrasp.R"
/home/swapnil/tools/GGRaSP-master/ggrasp.R -i $wd/all.ANI.tab -d 100 -h 5 -o $wd/representative_of_a_clusters_at_95_ANI --plottree 
rm Rplots.pdf



###############################################################################
## old discarded script
exit
#------------------------------------------------------------------------------
## old matrix-creation step
(rm $wd/tmp/$F1.ANI.tmp) > /dev/null 2>&1
for F1 in $(cat $list);do
	for F2 in $(cat $list); do
	awk '$1 == "'$F1'" && $2 == "'$F2'" {print 100-$3}' $wd/tmp/output.csv >> $wd/tmp/$F1.ANI.tmp
	done
    sed -i '1 i\'$F1'' $wd/tmp/$F1.ANI.tmp
done
exit
###############################################################################