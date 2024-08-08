
#!/bin/bash
###############################################################################
## header
    start_time=$(date +"%Y%m%d_%H%M%S")
###############################################################################
echo "script 0061_identification_by_gtdbtk started -------------------------------------"
###############################################################################
## step-01: preparation

    if [ -f list.fasta.txt ]; then 
        list=list.fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g' | sed 's/list\.//g' | sed 's/\.txt//g'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    (mkdir -p results/0061_identification_by_gtdbtk/results) > /dev/null 2>&1
    (mkdir -p results/0061_identification_by_gtdbtk/tmp/lists ) > /dev/null 2>&1
    (mkdir -p results/0061_identification_by_gtdbtk/tmp/sbatch ) > /dev/null 2>&1
    (mkdir -p results/0061_identification_by_gtdbtk/tmp/slurm ) > /dev/null 2>&1

    for i in $(cat $list); do 
        echo -e "results/0059_metagenome_binning_by_metabat_for_megahit_assemblies/all_fasta/$i.fasta\t$i" \
        >> results/0061_identification_by_gtdbtk/tmp/new.list
    done 
    list=results/0061_identification_by_gtdbtk/tmp/new.list


    ( rm results/0061_identification_by_gtdbtk/tmp/lists/*.* ) > /dev/null 2>&1
    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 10 ))
    split -l "$lines_per_part" -a 3 -d "$list" list.0061_identification_by_gtdbtk_
    mv list.0061_identification_by_gtdbtk_* results/0061_identification_by_gtdbtk/tmp/lists/

###############################################################################
## step-02: create files for gtdbtk

    # for sublist in $( ls results/0061_identification_by_gtdbtk/tmp/lists/ ) ; do
    #     echo adding prefix and suffix to $sublist
    #     sed "s|^|/work/groups/VEO/databases/genomes_bacteria_bvbrc/genomes/bacteria/fna/|" results/0061_identification_by_gtdbtk/tmp/lists/$sublist  | sed "s/$/\.fna/" > results/0061_identification_by_gtdbtk/tmp/lists/$sublist.tmp
    #     paste results/0061_identification_by_gtdbtk/tmp/lists/$sublist.tmp results/0061_identification_by_gtdbtk/tmp/lists/$sublist > results/0061_identification_by_gtdbtk/tmp/lists/$sublist.tsv
    #     rm results/0061_identification_by_gtdbtk/tmp/lists/$sublist
    #     rm results/0061_identification_by_gtdbtk/tmp/lists/$sublist.tmp
	# done

###############################################################################
## run gtdbtk
    for sublist in $( ls results/0061_identification_by_gtdbtk/tmp/lists/ ) ; do
        echo $sublist
        sed "s#ABC#$sublist#g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0061_identification_by_gtdbtk.sbatch \
        > results/0061_identification_by_gtdbtk/tmp/sbatch/0061_identification_by_gtdbtk.$sublist.sbatch
        sbatch results/0061_identification_by_gtdbtk/tmp/sbatch/0061_identification_by_gtdbtk.$sublist.sbatch
    done 

###############################################################################
echo "script 0061_identification_by_gtdbtk ended -------------------------------------"
###############################################################################
## footer
    end_time=$(date +"%Y%m%d_%H%M%S")
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/time_calculations.sh "$start_time" "$end_time"
###############################################################################

###############################################################################
## old or unused scripts
###############################################################################

    ## running gtdb-tk
    # source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    # conda env config vars set GTDBTK_DATA_PATH="/work/groups/VEO/databases/gtdbtk/r207_v"
    # conda activate gtdbtk_v2.1.1
    # conda activate gtdbtk_v2.1.0
    
    # gtdbtk classify_wf --cpus 20 \
    # --genome_dir results/0061_identification_by_gtdbtk/fasta/ \
    # --out_dir results/0061_identification_by_gtdb/results --extension fasta
###############################################################################