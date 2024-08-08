#!/bin/bash
## step-4: Counting OTUs from each         
    for sublist in $(cat tmp/step_4/list.OTUs_sorted_sublist.txt ); do
        if [ ! -d tmp/step_4/OTU_files/seperated/$sublist ] ; then
            echo "running $sublist"
            mkdir tmp/step_4/OTU_files/seperated/$sublist
            
            for OTU_id in $(cat tmp/step_4/sublist/$sublist); do
                echo "$OTU_id --------------------------------------------------------------"
                for run_id in $(cat tmp/step_2/list.run_id_unique_biom.txt); do
                    OTU_id_content=$(grep -w "$OTU_id" tmp/step_3/OTU_files/raw_files/"$run_id"*.tsv | awk '{print $2}')
                    if [ -z "$OTU_id_content" ]; then
                        echo $OTU_id 0 >> tmp/step_4/OTU_files/seperated/$sublist/"$run_id"_OTUs.seperated.tsv
                        else
                        echo $OTU_id $OTU_id_content >> tmp/step_4/OTU_files/seperated/$sublist/"$run_id"_OTUs.seperated.tsv
                    fi 
                done
            done
            echo "finished $sublist"
        fi

    done
