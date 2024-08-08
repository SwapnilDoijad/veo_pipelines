#!/bin/bash
###############################################################################
## header
    pipeline=0334_ANI_by_mash_compare_two_sequences
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline --------------------------------------"
###############################################################################
## preparation
    fasta_dir=$(grep "my_fasta_dir" $parameters | awk '{print $NF}')
    ls $fasta_dir/ | sed 's/.fasta//g' > list.for_0334.txt
    create_directories_structure_1 $wd
###############################################################################
## step-01: sketching for all files for faster comparions

    mkdir -p $raw_files/sketch > /dev/null 2>&1
    if [ ! -f results/0331_ANI_by_minhash/msh/mash_sketch.msh ] ; then 

        ( /home/groups/VEO/tools/mash/v2.3/mash sketch \
        -s 200 \
        -o $raw_files/sketch/all_files.msh \
        $fasta_dir/*.fasta )> /dev/null 2>&1

        else
        echo "sketching already finished"
    fi 

###############################################################################
## step-02: sketching for every single file

    mkdir -p $raw_files/sketch > /dev/null 2>&1

    export raw_files=$raw_files
    export fasta_dir=$fasta_dir
    # Define the function for sketching
    sketch_function() {
        i="$1"
        /home/groups/VEO/tools/mash/v2.3/mash sketch \
        -s 200 \
        -o "$raw_files/sketch/$i.msh" \
        "$fasta_dir/$i.fasta" >/dev/null 2>&1
        echo "sketching: $i finished"
    }

    export -f sketch_function
    cat list.for_0334.txt | /home/groups/VEO/tools/parallel/v20230822/src/parallel -j 80 sketch_function

###############################################################################
## step-04: calculate distances for every single file

    mkdir -p $raw_files/dist > /dev/null 2>&1

    export raw_files=$raw_files
    export fasta_dir=$fasta_dir
    export wd=$wd

    dist_function() {
        i="$1"
        /home/groups/VEO/tools/mash/v2.3/mash dist \
        "$raw_files/sketch/$i.msh" \
        "$raw_files/sketch/all_files.msh" \
        | sort -gk3 \
        | sed "s|$fasta_dir||g" \
        | awk '$3 < 0.1 {print}' \
        > "$raw_files/dist/$i.dist"
        matches=$(wc -l "$raw_files/dist/$i.dist" | awk '{print $1}') 
        echo "distance: $i : $matches" | tee -a >> $wd/results.out
    }

    export -f dist_function
    cat list.for_0334.txt | /home/groups/VEO/tools/parallel/v20230822/src/parallel -j 80 dist_function

###############################################################################
