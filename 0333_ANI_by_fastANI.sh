#!/bin/bash
###############################################################################
#41 fastANI
# conda create --name fastani
# conda install -c bioconda fastani
###############################################################################
echo "started.... step-41 pyANI ----------------------------------------------"
###############################################################################
    #source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    #conda activate fastani

    (mkdir results) > /dev/null 2>&1
    (mkdir results/041_fastANI) > /dev/null 2>&1
    (mkdir results/041_fastANI/tmp) > /dev/null 2>&1
#------------------------------------------------------------------------------
    if [ -f list.bacterial_fasta.txt ]; then 
        list=list.bacterial_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi
# #------------------------------------------------------------------------------
# cp $list results/041_fastANI/tmp/list.fastANI.txt
# sed -i '/^\s*$/d' results/041_fastANI/tmp/list.fastANI.txt
# sed -i "s/^/results\/0040_assembly\/all_fasta\//" results/041_fastANI/tmp/list.fastANI.txt
# sed -i "s/$/\.fasta/" results/041_fastANI/tmp/list.fastANI.txt

# echo "runnig fastANI..."
# /home/groups/VEO/tools/fastANI/v1.33/fastANI --ql results/041_fastANI/tmp/list.fastANI.txt --rl results/041_fastANI/tmp/list.fastANI.txt -o results/041_fastANI/tmp/output.csv -t 60 --matrix #) > /dev/null 2>&1
# echo "fastANI finished, will create matrix and tree"

# sed -i -e 's/results\/0040_assembly\/all_fasta\///g' results/041_fastANI/tmp/output.csv.matrix
# sed -i "s/\.fasta//g" results/041_fastANI/tmp/output.csv.matrix

# sed -i "s/results\/0040_assembly\/all_fasta\///g" results/041_fastANI/tmp/output.csv
# sed -i "s/\.fasta//g" results/041_fastANI/tmp/output.csv

#------------------------------------------------------------------------------
## matrix-creation step
    cat results/041_fastANI/tmp/output.csv.matrix | sed '1d' > results/041_fastANI/tmp/all.distance.for_R.out.2.tab
    cp results/041_fastANI/tmp/all.distance.for_R.out.2.tab results/out.tab
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/transpose.mash.sh
    mv results/out.t.tab results/041_fastANI/tmp/all.distance.for_R.out.t.tab
    awk 'NR==FNR{ a[NR+1]=$0 FS 0; next }{ sub(/^ +/,""); print (FNR==1)? 0:a[FNR],$0 } END{ print a[FNR+1] }' results/041_fastANI/tmp/all.distance.for_R.out.2.tab results/041_fastANI/tmp/all.distance.for_R.out.t.tab > results/041_fastANI/tmp/all.distance.for_R.matrix.tab
    sed -i 's/ /\t/g' results/041_fastANI/tmp/all.distance.for_R.matrix.tab
    sed -e "1,/0/s/0//" results/041_fastANI/tmp/all.distance.for_R.matrix.tab > results/041_fastANI/all.ANI.tab

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate R
    Rscript /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/plot_and_tree.fastANI-distance.r
    mv "Rplots.pdf" results/041_fastANI/
    mv tree.nwk results/041_fastANI/
###############################################################################
echo "completed.... step-41 pyANI --------------------------------------------"
###############################################################################
exit

#------------------------------------------------------------------------------
# get a representative of a clutster at 95% (-h 5)
echo "running ggrasp.R"
/home/swapnil/tools/GGRaSP-master/ggrasp.R -i results/041_fastANI/all.ANI.tab -d 100 -h 5 -o results/041_fastANI/representative_of_a_clusters_at_95_ANI --plottree 
rm Rplots.pdf



###############################################################################
## old discarded script
exit
#------------------------------------------------------------------------------
## old matrix-creation step
(rm results/041_fastANI/tmp/$F1.ANI.tmp) > /dev/null 2>&1
for F1 in $(cat $list);do
	for F2 in $(cat $list); do
	awk '$1 == "'$F1'" && $2 == "'$F2'" {print 100-$3}' results/041_fastANI/tmp/output.csv >> results/041_fastANI/tmp/$F1.ANI.tmp
	done
    sed -i '1 i\'$F1'' results/041_fastANI/tmp/$F1.ANI.tmp
done
exit
###############################################################################