#!/bin/bash
#SBATCH --job-name 0224_plasmid_detection_by_platon
#SBATCH --partition=long
#SBATCH --output results/0224_plasmid_detection_by_platon/tmp/slurm/%j.out
#SBATCH --error results/0224_plasmid_detection_by_platon/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
## 00: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    pipeline=0224_plasmid_detection_by_platon
    wd=results/$pipeline
    sublist=$wd/tmp/lists/ABC
    fasta_path=$(grep my_fasta_path tmp/parameters/$pipeline* | awk '{print $2}')
###############################################################################
## 01: run platon

    conda activate platon_v1.6
    for i in $(cat $sublist); do
        log "STARTED : $pipeline : $i"
        (mkdir $wd/raw_files/$i) > /dev/null 2>&1 

        platon \
        -d /work/groups/VEO/databases/platon/v20230215/ \
        -o $wd/raw_files/$i \
        $fasta_path/$i.fasta 
        
        log "FINISHED : $pipeline : $i"
    done

    if [ ! -f $wd/contigs_results.tab ]; then 
        echo "ID	Length	Coverage	# ORFs	RDS	Circular	Inc Type(s)	# Replication	# Mobilization	# OriT	# Conjugation	# AMRs	# rRNAs	# Plasmid Hits" > $wd/results.tab
    fi

    for i in $(cat $sublist); do
        tail -n +2 $wd/raw_files/$i/$i.contigs.tsv >> $wd/contigs_results.tab
    done

    for i in $(cat $sublist); do
        contigs_sum=$( awk -F '\t' '{sum += $2} END {print sum}' $wd/raw_files/$i/$i.contigs.tsv )
        echo $i $contigs_sum >> $wd/contigs_sum_results.tab
    done
        sed -i '1 i\isolate plasmid_contig_sum' $wd/contigs_sum_results.tab

###############################################################################