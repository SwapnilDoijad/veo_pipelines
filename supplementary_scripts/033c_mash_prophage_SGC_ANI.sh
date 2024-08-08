#!/bin/bash
l=$(cat original_list_name.tmp)
list_copied_fasta=list."$l"_copied.txt
    for my_fasta_prophage_copied_sublist in $(cat results/33_minhash_prophage_SGC/distance/list/list."$l"_copied_sublist.txt); do
        if [ ! -d results/33_minhash_prophage_SGC/distance/sublist/$my_fasta_prophage_copied_sublist ]; then 
            mkdir results/33_minhash_prophage_SGC/distance/sublist/$my_fasta_prophage_copied_sublist 

            for fasta1 in $(cat results/33_minhash_prophage_SGC/distance/list/$my_fasta_prophage_copied_sublist ); do
                echo "started $my_fasta_prophage_copied_sublist $fasta1 "
                if [ ! -f results/33_minhash_prophage_SGC/distance/$fasta1.distance.txt ] ; then
                    for fasta2 in $(cat $list_copied_fasta ); do
                        /home/groups/VEO/tools/mash/v2.3/mash dist \
                        results/33_minhash_prophage_SGC/msh/$fasta1.mash_sketch.msh \
                        results/33_minhash_prophage_SGC/msh/$fasta2.mash_sketch.msh \
                        >> results/33_minhash_prophage_SGC/distance/sublist/$my_fasta_prophage_copied_sublist/$fasta1.distance.txt
                    done
                fi 
            echo "finished $fasta1"
            done
        echo "finished $my_fasta_prophage_copied_sublist"
        fi
    done
