#!/bin/bash
for sublist in $(cat results/0641_vibrant/tmp_sublist/list.all_sublist.txt ); do
    echo "sublist $sublist"
    if [ ! -d results/0641_vibrant/raw_files/$sublist ] ; then
        mkdir results/0641_vibrant/raw_files/$sublist
        for fasta_from_sublist in $(cat results/0641_vibrant/tmp_sublist/$sublist ); do 
            echo "sublist $sublist running"

            source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
            conda activate vibrant_v1.2.0

            if [ ! -d results/0641_vibrant/raw_files/$sublist/VIBRANT_"$fasta_from_sublist" ]; then
                echo $fasta_from_sublist
                VIBRANT_run.py \
                -i results/0040_assembly/all_fasta/$fasta_from_sublist.fasta \
                -t 40 \
                -folder results/0641_vibrant/raw_files/$sublist/$fasta_from_sublist \
                -d /work/groups/VEO/databases/vibrant/v20230318/databases/ \
                -m /work/groups/VEO/databases/vibrant/v20230318/files/ 
                else
                echo "$fasta_from_sublist finished"
            fi

            conda deactivate
        done 
    fi
done

mv -r results/0641_vibrant/raw_files/$sublist/ results/0641_vibrant/raw_files/