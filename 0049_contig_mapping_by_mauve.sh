#!/bin/bash
###############################################################################
# 0411_contig_mapping_by_mauve copy
###############################################################################
echo "started.... 0411_contig_mapping_by_mauve copy ---------------------------------"
###############################################################################
## step-01: prepare
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

    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep -w "^fasta" result_summary.read_me.txt | awk '{print $NF}' )
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi
 
    if [ -f result_summary.read_me.txt ]; then
        ref_fasta=$(grep ref_fasta result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide ref_fasta"
        read ref_fasta
    fi

    (mkdir -p results/0049_contig_mapping_by_mauve/tmp/raw_files) > /dev/null 2>&1
    (mkdir -p results/0049_contig_mapping_by_mauve/tmp/slurm) > /dev/null 2>&1
    (mkdir -p results/0049_contig_mapping_by_mauve/tmp/sbatch) > /dev/null 2>&1
    (mkdir -p results/0049_contig_mapping_by_mauve/tmp/lists) > /dev/null 2>&1
    (mkdir -p results/0049_contig_mapping_by_mauve/all_fasta) > /dev/null 2>&1

###############################################################################
## step-02: copy fasta files and run mauve

    for i in $(cat $list); do 
        # cp $fasta_file_path/raw_files/$i/$i.contigs-filtered.fasta results/0049_contig_mapping_by_mauve/tmp/raw_files

        echo "running mauve for $i"
        WorDir=$(echo $PWD)

        cd /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13
        
        java -Xmx5000m -cp Mauve.jar org.gel.mauve.contigs.ContigOrderer \
        -output $i \
        -ref $WorDir/$ref_fasta \
        -draft "$WorDir/$fasta_file_path/raw_files/$i/$i.contigs-filtered.fasta" #) > /dev/null 2>&1 
 
        cd $WorDir

        Var1=$(ls /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13/$i/ | sort -r | head -1)
        cp /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13/$i/$Var1/$i.contigs-filtered.fasta results/0049_contig_mapping_by_mauve/tmp/raw_files/$i.contigs-filtered.aligned.fasta
        cp results/0049_contig_mapping_by_mauve/tmp/raw_files/$i.contigs-filtered.aligned.fasta results/0049_contig_mapping_by_mauve/all_fasta/$i.contigs-filtered.aligned.joined.fasta
        sed -i 's/>.*/NNNNNNNNNN/g' results/0049_contig_mapping_by_mauve/all_fasta/$i.contigs-filtered.aligned.joined.fasta
        sed -i "1i "'>'$i"" results/0049_contig_mapping_by_mauve/all_fasta/$i.contigs-filtered.aligned.joined.fasta

        (rm -rf /home/groups/VEO/tools/mauve/v2.4.0/mauve_snapshot_2015-02-13/$i) > /dev/null 2>&1

    done 
###############################################################################