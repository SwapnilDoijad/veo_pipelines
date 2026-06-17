#!/bin/bash
#SBATCH --job-name 0135_phylogeny_by_fastANI
#SBATCH --partition=gpu,gpu-test
#SBATCH --output results/0135_phylogeny_by_fastANI/tmp/slurm/%j.out
#SBATCH --error  results/0135_phylogeny_by_fastANI/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
## step-01: preparation
    pipeline=0135_phylogeny_by_fastANI
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    parameter_file=tmp/parameters/$pipeline.*
    fasta_path=$(grep my_fasta_path $parameter_file | awk '{print $2}')
    ls $fasta_path/*.fasta > results/$pipeline/tmp/list.fastANI.txt
###############################################################################
## step-02: run fastANI
    if [ ! -f results/$pipeline/raw_files/output.csv ] ; then 
        log "STARTED : $pipeline : fastANI run"

        /home/groups/VEO/tools/fastANI/v1.33/fastANI \
        --ql results/$pipeline/tmp/list.fastANI.txt \
        --rl results/$pipeline/tmp/list.fastANI.txt \
        -o results/$pipeline/raw_files/output.csv \
        --fragLen 200 \
        --matrix \
        -t 40

        log "FINISHED : $pipeline : fastANI run"
        else 
        log "ALREADY FINISHED : $pipeline : fastANI run"
    fi

###############################################################################
## step-03: matrix-creation step

    log "fastANI finished, will create matrix and tree"

    cp ${raw_files}/output.csv.matrix ${wd}/tmp/output.csv.matrix.backup
    sed -i "s/NA/0/g" ${raw_files}/output.csv.matrix
    sed -i -e "s|$fasta_path/||g" ${raw_files}/output.csv.matrix
    sed -i "s/\.fasta//g" ${raw_files}/output.csv.matrix
    cp ${raw_files}/output.csv ${wd}/tmp/output.csv.backup
    sed -i "s/NA/0/g" ${raw_files}/output.csv
    sed -i "s|$fasta_path/||g" ${raw_files}/output.csv
    sed -i "s/\.fasta//g" ${raw_files}/output.csv

#------------------------------------------------------------------------------
## matrix-creation step
    cat ${raw_files}/output.csv.matrix | sed '1d' > $wd/tmp/all.distance.for_R.out.2.tab
    cp $wd/tmp/all.distance.for_R.out.2.tab results/$pipeline/out.tab

    awk '
    { 
        for (i=1; i<=NF; i++)  {
            a[NR,i] = $i
        }
    }
    NF>p { p = NF }
    END {    
        for(j=1; j<=p; j++) {
            str=a[1,j]
            for(i=2; i<=NR; i++){
                str=str" "a[i,j];
            }
            print str
        }
    }' ${wd}/out.tab > ${wd}/out.t.tab


    mv ${wd}/out.t.tab $wd/tmp/all.distance.for_R.out.t.tab
    
    awk 'NR==FNR{ a[NR+1]=$0 FS 100; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' \
    $wd/tmp/all.distance.for_R.out.2.tab $wd/tmp/all.distance.for_R.out.t.tab > $wd/tmp/all.distance.for_R.matrix.tab
    
    sed -i 's/ /\t/g' $wd/tmp/all.distance.for_R.matrix.tab
    sed -e "1,/0/s/0//" $wd/tmp/all.distance.for_R.matrix.tab > $wd/all.ANI.tab

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate R
    Rscript /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/plot_and_tree.fastANI-distance.r \
    -i $wd/all.ANI.tab \
    -o $wd/fastANI_tree \
    # mv "Rplots.pdf" $wd/
    # mv tree.nwk $wd/
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