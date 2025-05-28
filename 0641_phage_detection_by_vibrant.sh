#!/bin/bash
###############################################################################
## header
    pipeline=0641_phage_detection_by_vibrant
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation
	fasta_dir_path=$(grep "my_fasta_path" $parameters | awk '{print $2}')
    ls $fasta_dir_path/*.fasta | awk -F'/' '{print $NF}' | sed 's/.fasta//g' > list.$pipeline.txt
    list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
    log "STARTED : $pipeline ---------------------------------"
###############################################################################
## check if last file if completely processed 

    # touch completely_processed.tmp
    # last_fasta=$(tail -1 $list)
    #     while ! grep -q "$last_fasta finished" completely_processed.tmp ; do
    #         sleep 60
    #         echo "waiting $last_fasta to be completely processed"
    #         cat slurm* | grep "$last_fasta finished" > completely_processed.tmp
    #     done 
    # (rm completely_processed.tmp) > /dev/null 2>&1

    # echo "vibrant finished for all samples"

###############################################################################
## split the prophage sequences
    # for i in $(cat $list ); do
    #     if [ -f results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/"$i".phages_combined.fna ] ; then
    #         echo $i
    #         (mkdir results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted ) > /dev/null 2>&1
    #         sed -i 's/ /_/g' results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/"$i".phages_combined.fna
    #         if [ -f results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted/*.fsa ] ; then 
    #             perl /home/groups/VEO/tools/suppl_scripts/split_fasta.pl \
    #             --input_file=results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/"$i".phages_combined.fna \
    #             --output_dir=results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted
    #             mv results/0641_vibrant/raw_files/VIBRANT_"$i"/VIBRANT_phages_"$i"/splitted/*.fsa results/0641_vibrant/all_fasta 
    #         fi
    #     fi
    # done
###############################################################################
## list the prophages
    # ls results/0641_vibrant/all_fasta/ | sed 's/\.fsa//g' > list."$list"_prophages.txt
###############################################################################
## creating prophage matrix 
 
    # (mkdir results/33_minhash_prophage_SGC_for_test_run/combining_results) > /dev/null 2>&1

    # for i in $(cat list.viciae89_final_prophage.txt); do
    # echo $i
    #     echo $i > results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt
    #     for genome in $(cat list.viciae89_carrying_prophage.txt); do
    #         prophage=$(echo "$genome"_"$i")
    #         V2=$(grep $prophage results/33_minhash_prophage_SGC_for_test_run/tmp/new_name)
    #         #echo $V2

    #         if [ ! -z $V2 ]; then 
    #             echo "1" >> results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt
    #             else
    #             echo "0" >> results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt
    #         fi
    #     done
    # done

    #     cp list.viciae89_carrying_prophage.txt results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab
    #     sed -i '1i\\' results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab
    # for i in $(cat list.viciae89_final_prophage.txt); do
    #     paste results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab results/33_minhash_prophage_SGC_for_test_run/combining_results/$i.txt > results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tmp
    #     mv results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tmp results/33_minhash_prophage_SGC_for_test_run/combining_results/matrix.tab
    # done 
###############################################################################