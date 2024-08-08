#!/bin/bash
###############################################################################
# b064 vibrant
###############################################################################
## installation steps
## conda create --name vibrant
## conda activate vibrant
## conda install -c bioconda vibrant==1.2.0
## download-db.sh /work/groups/VEO/databases/vibrant
###############################################################################
## step-00: preparations
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate vibrant_v1.2.0

    if [ -f list.my_fasta.txt ]; then 
        list=list.my_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    (mkdir -p results/0641_vibrant/raw_files ) > /dev/null 2>&1
    (mkdir -p results/0641_vibrant/tmp_sublist ) > /dev/null 2>&1
###############################################################################
## step-01: run vibrant tool

    ## vibrant tool is hmmbased tool and take long to run 
    ## therfore, need to run on the sbatch

    ## first split the list 
        split -d -l 100 $list "$l"_sublist
        ls "$l"_sublist* > results/0641_vibrant/tmp_sublist/list."$l"_sublist.txt
        mv "$l"_sublist* results/0641_vibrant/tmp_sublist/
    
    cat results/0641_vibrant/tmp_sublist/list."$l"_sublist.txt

    ## run the sbatch for each list 
    for sublist in $(cat results/0641_vibrant/tmp_sublist/list.all_sublist.txt ) ; do
        sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/0641_vibrant.sbatch
        until test -d results/0641_vibrant/raw_files/$sublist ; do
            echo "waiting for results/0641_vibrant/raw_files/$sublist"
            sleep 5
        done
    done 


    ## check if last file if completely processed 
    touch completely_processed.tmp
    last_fasta=$(tail -1 $list)
        while ! grep -q "$last_fasta finished" completely_processed.tmp ; do
            sleep 60
            echo "waiting $last_fasta to be completely processed"
            cat slurm* | grep "$last_fasta finished" > completely_processed.tmp
        done 
    (rm completely_processed.tmp) > /dev/null 2>&1

    echo "vibrant finished for all samples"
exit
###############################################################################
## split the prophage sequences, 
for i in $(cat $list ); do
    if [ -f results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/"$i".phages_combined.fna ] ; then
        echo $i
        (mkdir results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted ) > /dev/null 2>&1
        sed -i 's/ /_/g' results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/"$i".phages_combined.fna
        if [ -f results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted/*.fsa ] ; then 
            perl /home/groups/VEO/tools/suppl_scripts/split_fasta.pl \
            --input_file=results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/"$i".phages_combined.fna \
            --output_dir=results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted
            mv results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted/*.fsa results/0641_vibrant/all_fasta 
        fi
    fi
done
###############################################################################
## list the prophages
ls results/0641_vibrant/all_fasta/ | sed 's/\.fsa//g' > list."$list"_prophages.txt
###############################################################################

exit

###############################################################################
## creating prophage matrix 
 
(mkdir results/33_minhash_prophage_SGC_for_test_run/combining_results) > /dev/null 2>&1

for i in $(cat list.viciae89_final_prophage.txt); do
echo $i
    echo $i > results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt
    for genome in $(cat list.viciae89_carrying_prophage.txt); do
        prophage=$(echo "$genome"_"$i")
        V2=$(grep $prophage results/33_minhash_prophage_SGC_for_test_run/tmp/new_name)
        #echo $V2

        if [ ! -z $V2 ]; then 
            echo "1" >> results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt
            else
            echo "0" >> results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt
        fi
    done
done

    cp list.viciae89_carrying_prophage.txt results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab
    sed -i '1i\\' results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab
for i in $(cat list.viciae89_final_prophage.txt); do
    paste results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt > results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tmp
    mv results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tmp results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab
done 
###############################################################################