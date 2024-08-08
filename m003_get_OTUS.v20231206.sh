#!/bin/bash 
###############################################################################
## header
    # m003 get OTUs 003_get_OTUS.v20231206.sh
    ## script adapted from scripts/database_maintainance/mgnify/003_get_OTUS.v20230807.sh
    ## for one sample-id more than one run-ids present  
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
###############################################################################
## preparation
    timestamp=$(date +%F_%T)
    SECONDS=0    
    (rm results.summary.read_me.txt) > /dev/null 2>&1
    (touch results.summary.read_me.txt) > /dev/null 2>&1
    if [ ! -f list.all_samples.txt ] ; then 
        echo "provide list of samples (for e.g. all)"
        echo "--------------------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "--------------------------------------------------------------------------------"
        read l
        sample_id_list_0=$(echo "list.$l.txt")
        else
        sample_id_list_0=list.all_samples.txt
    fi

        sort -u $sample_id_list_0 > list.all_samples_unique.txt
        sample_id_list=list.all_samples_unique.txt
        (mkdir tmp) > /dev/null 2>&1
    number_of_original_samples_ids=$(cat $sample_id_list_0 | wc -l )
    number_of_final_nonduplicate_samples_ids=$(cat $sample_id_list | wc -l )
    number_of_duplicate_sample_ids="$(($number_of_original_samples_ids-$number_of_final_nonduplicate_samples_ids))"
    echo script_started_at $timestamp >> results.summary.read_me.txt
    echo number_of_original_samples_ids $number_of_original_samples_ids >> results.summary.read_me.txt
    echo number_of_duplicate_sample_ids $number_of_duplicate_sample_ids >> results.summary.read_me.txt
    echo number_of_final_nonduplicate_samples_ids $number_of_final_nonduplicate_samples_ids >> results.summary.read_me.txt

###############################################################################
## step-1: get run_ids for sample
    if [ ! -d tmp/step_1 ]; then 
        echo "STARTED step-1: get run_ids for sample------------------------------------------"
        (mkdir tmp/step_1) > /dev/null 2>&1
        (mkdir tmp/step_1/run_ids_for_sample) > /dev/null 2>&1

        ## 20231204 working bash loop, demoted as below python script is faster
            # for sample_id in $(cat $sample_id_list); do
            #     if [ ! -f tmp/step_1/run_ids_for_sample/list.run_ids_for_sample_"$sample_id".txt ] ; then 
            #         echo "getting run_ids for sample $sample_id"
            #         study_id=$(grep $sample_id /work/groups/VEO/databases/mgnify/mgnify_all_ids_combined.20230127.tab | awk '{print $3}' )
            #         ## get run ids 
            #         ## sometime there are more than one run ids and run ids are also "null" (@Swapnil need to cross check why these are "null" occur)
            #         grep $sample_id /work/groups/VEO/databases/mgnify/mgnify_all_ids_combined.20230127.tab | awk '{print $2}' | sed -z 's/_/ /g' | sed 's/ /\n/g' | sed 's/null//g' > tmp/step_1/run_ids_for_sample/list.run_ids_for_sample_"$sample_id".txt
            #     fi
            # done

        ## 20231204 python script faste than above bash loop
            python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUS_step_1_get_run_ids.py

        ## 20231204 working bash loop, demoted as below python script is faster
            # if [ ! -f tmp/step_1/run_ids_unique.txt ]; then 
            #     for sample_id in $(cat $sample_id_list); do
            #         for run_id in $(cat tmp/step_1/run_ids_for_sample/list.run_ids_for_sample_"$sample_id".txt); do
            #             echo $sample_id $run_id >> tmp/step_1/sample_ids_run_ids.txt
            #             echo $run_id >> tmp/step_1/run_ids.txt
            #         done
            #     done
            # fi

        ## 20231204 python script faste than above bash loop
            python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUS_step_1_combine_smaple_and_run_ids.py

            sort -u tmp/step_1/run_ids.txt > tmp/step_1/run_ids_unique.txt

        number_of_total_run_ids=$(cat tmp/step_1/run_ids.txt | wc -l)
        number_of_unique_run_ids=$(cat tmp/step_1/run_ids_unique.txt | wc -l)
        echo for $number_of_final_nonduplicate_samples_ids sample_ids number_of_run_ids found $number_of_total_run_ids >> results.summary.read_me.txt
        echo of $number_of_total_run_ids number_of_total_run_ids unique run_ids are $number_of_unique_run_ids >> results.summary.read_me.txt


        echo "FINISHED step-1: get run_ids for sample-----------------------------------------"
        else
        echo "ALREADY FINISHED: step-1: get run_ids for sample -------------------------------"
    fi

###############################################################################
## step-2: get OTU file path based on the run ids, check if these OTU files are biom files

    if [ ! -d tmp/step_2 ] ; then 
        echo "STARTED step-2: get OTU file path based on the run ids--------------------------"
        (mkdir tmp/step_2) > /dev/null 2>&1

        ## 20231204 : 
        # find /work/groups/VEO/databases/mgnify/OTU_biom_files/ -type f > /work/groups/VEO/databases/mgnify/mgnify_all_OTUs_table_available.20231204.tab

        ## 20231204 : below steps were demoted as /home/xa73pav/scripts/database_maintainance/mgnify/OTU_table/archieved/all/ contains all the biom format files and 
            ## tmp/step_2/list.run_id_unique_biom_path.txt files can straight forwrad can be written

            (rm tmp/step_2/list.OTUs_absent.txt) > /dev/null 2>&1
            (rm tmp/step_2/list.OTUs_table_absent.txt) > /dev/null 2>&1
            (rm tmp/step_2/list.OTUs_present_and_their_path.txt) > /dev/null 2>&1
            if [ ! -f tmp/step_2/list.OTUs_table_present_and_their_path_unique.txt ]; then 

                ## 20231204 : bash loop script is demoted for speed by python script (see below)
                # for run_id in $(cat tmp/step_1/run_ids_unique.txt); do
                #     echo "getting OTU file path for run-id $run_id"
                #         OTUs_table_path=$(grep $run_id /work/groups/VEO/databases/mgnify/mgnify_all_OTUs_table_available.20230127.tab )
                #         if [ -z $OTUs_table_path ]; then 
                #             echo "$sample_id $run_id" >> tmp/step_2/list.OTUs_table_absent.txt
                #             else 
                #             echo "$OTUs_table_path" >> tmp/step_2/list.OTUs_table_present_and_their_path.txt
                #         fi 
                # done

                ## 20231204 : for above loop this python script is fasters
                    python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUS_step_2_check_otu_table_if_present.py
                    sort -u tmp/step_2/list.OTUs_table_present_and_their_path.txt > tmp/step_2/list.OTUs_table_present_and_their_path_unique.txt
                    sort -u tmp/step_2/list.OTUs_table_absent.txt > tmp/step_2/list.OTUs_table_absent_unique.txt
            fi

            ## 20231204 : the "find" step added on 20231204 only list biom format files, so below step is demoted
                ## and directly copy / created files to be in line with downstream
                    cp tmp/step_2/list.OTUs_table_present_and_their_path_unique.txt tmp/step_2/list.run_id_unique_biom_path.txt
                    touch tmp/step_2/list.run_id_unique_not_biom_path.txt
                    awk -F'/' '{print $NF}' tmp/step_2/list.run_id_unique_biom_path.txt | awk -F'_' '{print $1}' > tmp/step_2/list.run_id_unique_biom.txt

                    ## not all files are biom format (== normal format)
                    ## for downstream consistent processing, need to seperte biom and non-biom files
                        # if [ ! -f list.run_id_unique_biom.txt ]; then 
                        #     for OTU_file_path in $(cat tmp/step_2/list.OTUs_table_present_and_their_path_unique.txt); do
                        #         v1=$(grep -w "biom" $OTU_file_path)
                        #         if [ -z "$v1" ] ; then 
                        #         echo $OTU_file_path >> tmp/step_2/list.run_id_unique_not_biom_path.txt
                        #         else
                        #         echo $OTU_file_path >> tmp/step_2/list.run_id_unique_biom_path.txt
                        #         fi
                        #     done
                        # fi

                    ## get run ids which contains biom file 
                        # if [ ! -f tmp/step_3/list.run_id_unique_biom.txt ]; then 
                        #     for run_id_sorted_biom in $(cat tmp/step_2/list.run_id_unique_biom_path.txt ); do
                        #         echo $run_id_sorted_biom | awk -F'/' '{print $NF}' | awk -F'_' '{print $1}' >> tmp/step_2/list.run_id_unique_biom.txt
                        #     done
                        # fi 

        echo "FINISHED step-2: get OTU file path based on the run ids-------------------------"
        else
        echo "ALREADY FINISHED: step-2: get OTU file path based on the run ids ---------------"
    fi

    number_of_OTU_file_found=$(cat tmp/step_2/list.OTUs_table_present_and_their_path_unique.txt | wc -l)
    number_of_OTU_file_absent=$(cat tmp/step_2/list.OTUs_table_absent_unique.txt | wc -l)
    number_of_OTU_files_biome=$(cat tmp/step_2/list.run_id_unique_biom.txt | wc -l)
    number_of_OTU_files_not_biome=$(cat tmp/step_2/list.run_id_unique_not_biom_path.txt | wc -l)
    echo number_of_OTU_file_found $number_of_OTU_file_found >> results.summary.read_me.txt
    echo number_of_OTU_file_absent $number_of_OTU_file_absent >> results.summary.read_me.txt
    echo number_of_OTU_files_in_biom_format $number_of_OTU_files_biome >> results.summary.read_me.txt
    echo number_of_OTU_files_not_biom_format $number_of_OTU_files_not_biome >> results.summary.read_me.txt

###############################################################################
## step-3: get actual OTUs sort and list unique OTUs for further use
    if [ ! -d tmp/step_3 ] ; then 
        echo "STARTED step-3: get actual OTUs-------------------------------------------------"
        (mkdir tmp/step_3) > /dev/null 2>&1

        ## Copy OTU biom files
        if [ ! -f tmp/step_3/all.OTUs_sorted.tsv ]; then
            echo "Combinign OTU files"
            (mkdir tmp/step_3/OTU_files) > /dev/null 2>&1
            (mkdir tmp/step_3/OTU_files/raw_files/) > /dev/null 2>&1
            (rm tmp/step_3/OTU_files/all.tsv) > /dev/null 2>&1
            ## demoted the loop by below python script 
                # for otu_file in $(cat tmp/step_2/list.run_id_unique_biom_path.txt); do
                #     cp $otu_file tmp/step_3/OTU_files/raw_files/
                #     cat $otu_file >> tmp/step_3/OTU_files/all.tsv
                # done
            python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUS_step_3_get_otu_files.py

            ## get OTUs and taxonomies from  biom files
            sed -i '/taxonomy/d' tmp/step_3/OTU_files/all.tsv 
            sed -i '/biom/d' tmp/step_3/OTU_files/all.tsv

            awk '{print $1}' tmp/step_3/OTU_files/all.tsv > tmp/step_3/OTU_files/all.OTUs.tsv
            sort -u tmp/step_3/OTU_files/all.OTUs.tsv > tmp/step_3/all.OTUs_sorted.tsv

            awk '{print $3}' tmp/step_3/OTU_files/all.tsv > tmp/step_3/OTU_files/all.taxonomy.tsv
            sort -u tmp/step_3/OTU_files/all.taxonomy.tsv > tmp/step_3/all.taxonomy_sorted.tsv
        fi

        echo "FINISHED step-3: get actual OTUs------------------------------------------------"
        else
        echo "ALREADY FINISHED: step-3: get actual OTUs---------------------------------------"
    fi

    OTU_count=$(cat tmp/step_3/all.OTUs_sorted.tsv | wc -l)
    taxonomy_count=$(cat tmp/step_3/all.taxonomy_sorted.tsv | wc -l)
    echo "from $number_of_OTU_files_biome OTU_files total_OTUs_found $OTU_count " >> results.summary.read_me.txt
    echo "from $number_of_OTU_files_biome OTU_files total_taxonomy_found $taxonomy_count " >> results.summary.read_me.txt

###############################################################################
## step-4: Counting taxonomy from each run (sample)
    if [ ! -d tmp/step_4 ] ; then 
        (mkdir tmp/step_4 ) > /dev/null 2>&1
        echo "STARTED step-4: Counting taxonomy from each run-------------------------------------"
        (mkdir -p tmp/step_4/OTU_files ) > /dev/null 2>&1

        ## sometime list.run_id_unique_biom.txt contains duplicates and problematic for below process,
        ## thus need to remove again (@swapnil, need to look why there are duplicates in list.run_id_unique_biom.txt file)
        sort tmp/step_2/list.run_id_unique_biom.txt | uniq > tmp/step_4/list.run_id_unique_biom.sort_uniq.txt

        ## instead of sbatch, python script can do the job, really really faster
            # total_number_of_otu_ids=$(wc -l tmp/step_4/list.run_id_unique_biom.sort_uniq.txt | awk '{print $1}')
            # number_of_current_otu_id=0
            # remainining=$(echo $total_number_of_otu_ids)
            # for run_id in $( cat tmp/step_4/list.run_id_unique_biom.sort_uniq.txt ); do 
            #     if [ ! -f tmp/step_4/OTU_files/"$run_id"_OTUs.2.tsv ]; then 
            #         echo "processing $run_id ($number_of_current_otu_id finished, $remainining still to process)"
            #         python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUs_step_4.py \
            #         -i tmp/step_3/OTU_files/raw_files/"$run_id"_*.tsv \
            #         -o tmp/step_4/OTU_files/"$run_id"_OTUs.tsv
            #         awk '{print $2}' tmp/step_4/OTU_files/"$run_id"_OTUs.tsv > tmp/step_4/OTU_files/"$run_id"_OTUs.2.tsv
            #         number_of_current_otu_id=$(grep -nw "$run_id" tmp/step_4/list.run_id_unique_biom.sort_uniq.txt | cut -d ":" -f 1)
            #         remainining=$(( $total_number_of_otu_ids - $number_of_current_otu_id ))
            #         else
            #         echo "$run_id already finished"
            #     fi
            # done 
        # python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUs_step_4_count_OTUs.py
        python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_OTUs_step_4_count_taxonomy.py

        echo "FINISHED step-4: Counting OTUs from each run------------------------------------"
       else
        echo "ALREADY FINISHED: step-4: Counting OTUs from each run----------------------------"
    fi

###############################################################################
## step-5: Final table creation
    if [ ! -d tmp/step_5 ] ; then
        echo "RUNNING step-5: final table creation--------------------------------------------"
        (mkdir tmp/step_5 ) > /dev/null 2>&1
        (mkdir tmp/step_5/sbatch ) > /dev/null 2>&1
        (mkdir tmp/step_5/slurm ) > /dev/null 2>&1
        (mkdir tmp/step_5/list_out/ ) > /dev/null 2>&1
        (mkdir tmp/step_5/sublist_files ) > /dev/null 2>&1

        if [ ! -f tmp/step_5/list.run_id_unique_biom_subset.txt ]; then
            split -d -l 1000 tmp/step_2/list.run_id_unique_biom.txt run_id_unique_biom_subset
            ls run_id_unique_biom_subset* > tmp/step_5/list.run_id_unique_biom_subset.txt
            mv run_id_unique_biom_subset* tmp/step_5/list_out/
        fi

        ## first combine 1000 files
            for run_id_unique_biom_subset in $(cat tmp/step_5/list.run_id_unique_biom_subset.txt ); do
                sed "s/ABC/$run_id_unique_biom_subset/g" \
                /home/groups/VEO/scripts_for_users/supplementary_scripts/m003_get_taxonomy_abundance_table_step_5.sbatch \
                > tmp/step_5/sbatch/$run_id_unique_biom_subset.sbatch
                sbatch tmp/step_5/sbatch/$run_id_unique_biom_subset.sbatch
            done 

        ## wait till sbatch are finished
            sleep 20 # it take time to find node for sbatch files and create files
            for run_id_unique_biom_subset in $(cat tmp/step_5/list.run_id_unique_biom_subset.txt ); do
                echo run_id_unique_biom_subset $run_id_unique_biom_subset
                while [ ! -f "tmp/step_5/sublist_files/$run_id_unique_biom_subset.all.for_OTU_taxa.2.tsv.tmp" ]; do
                    echo "$run_id_unique_biom_subset not yet written, waiting for 60 seconds..."
                    sleep 60
                done
            done 

        cat tmp/step_3/all.taxonomy_sorted.tsv | sed '1i\taxonomy' > tmp/step_5/all.for_OTU_taxa.2.tsv.tmp
        ## now combine all sublist files 
            for run_id_unique_biom_subset in $(cat tmp/step_5/list.run_id_unique_biom_subset.txt ); do
                echo $run_id_unique_biom_subset
                paste tmp/step_5/all.for_OTU_taxa.2.tsv.tmp tmp/step_5/sublist_files/$run_id_unique_biom_subset.all.for_OTU_taxa.2.tsv.tmp > tmp/step_5/all.for_OTU_taxa.2.tsv.tmp2
                mv tmp/step_5/all.for_OTU_taxa.2.tsv.tmp2 tmp/step_5/all.for_OTU_taxa.2.tsv.tmp
            done

        mv tmp/step_5/all.for_OTU_taxa.2.tsv.tmp tmp/step_5/all.for_OTU_taxa.2.tsv.tab

        ## for final table we need final sample ids , here a file will be created which will have all \
        ## sample ids and run ids, this table will be used in the next step
        if [ ! -f tmp/step_5/list.final_sample_ids.txt ] ; then
            for run_id in $(cat tmp/step_2/list.run_id_unique_biom.txt); do
                echo "creating list.final_sample_ids.txt $run_id"
                final_sample_id=$(grep $run_id /work/groups/VEO/databases/mgnify/mgnify_all_ids_combined.20230127.tab | awk '{print $1}')
                echo $final_sample_id >> tmp/step_5/list.final_sample_ids.txt
            done 
        fi
        cat tmp/step_5/list.final_sample_ids.txt | tr "\n" "\t" | sed 's/\t$/\n/' | sed 's/^/taxonomy\t/' > tmp/step_5/list.final_sample_ids_as_header.txt
        cat tmp/step_5/list.final_sample_ids_as_header.txt tmp/step_5/all.for_OTU_taxa.2.tsv.tab > tmp/step_5/final_OTUs.tab

        cp tmp/step_5/final_OTUs.tab samples_and_their_OTUs.tab

        echo "FINISHED step-5: Combining OTUs of each run_id (as per all OTUs)----------------"
        else
        echo "ALREADY FINISHED step-5: Combining OTUs of each run_id (as per all OTUs)--------"
    fi

    number_of_final_taxa=$(cat tmp/step_3/all.taxonomy_sorted.tsv  | wc -l)
    echo "for $OTU_count OTUs number of taxa extracted $number_of_final_taxa" >> results.summary.read_me.txt
    tar -czvf final_OTUs.tab.tar.gz tmp/step_5/final_OTUs.tab
###############################################################################
## closing
    duration=$SECONDS
    echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
    
    exit
###############################################################################
