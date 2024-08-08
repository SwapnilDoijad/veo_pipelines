#!/bin/bash
###############################################################################
## header
    start_time=$(date +"%Y%m%d_%H%M%S")
##############################################################################
## step-01: preparations


    list=list.assembly_fastq.txt

    if [ -f $list ]; then
        if awk -F'\t' 'NF != 2 { exit 1 }' "$list"; then
        :
        else
            echo "The file $list does not contain tab-separated two columns."
            exit 1
        fi
    else
        echo "--------------------------------------------------------------------------------"
        echo "The file $list (first column: assembly_ids second column: fastq_ids) does not exist."
        echo "for e.g. (cat list.assembly_fastq.txt)"
        echo "ERZ1714330	SRR7497167"
        echo "ERZ1714339	SRR7497945"
        echo "ERZ1714332	SRR7499264"
        echo "--------------------------------------------------------------------------------"
        exit 1
    fi

    echo "--------------------------------------------------------------------------------"
    echo "provide your fastq file path"
    echo "for e.g. if your fastq files are present at my_data/fastqs/A.fastq"
    echo "provide my_data/fastqs"
    echo "--------------------------------------------------------------------------------"
    read fastq_path
    echo "okay, considering fastqs from $fastq_path"

    echo "--------------------------------------------------------------------------------"
    echo "provide your fasta file path"
    echo "for e.g. if your fasta files are present at my_data/fasta/A.fasta"
    echo "provide my_data/fasta"
    echo "--------------------------------------------------------------------------------"
    read fasta_path
    echo "okay, considering fastqs from $fasta_path"

    (mkdir -p results/0066_getSNPs_from_BAM_by_bcftools/raw_files ) > /dev/null 2>&1
    (mkdir -p results/0066_getSNPs_from_BAM_by_bcftools/tmp/lists ) > /dev/null 2>&1
    (mkdir -p results/0066_getSNPs_from_BAM_by_bcftools/tmp/sbatch ) > /dev/null 2>&1
    (mkdir -p results/0066_getSNPs_from_BAM_by_bcftools/tmp/slurm ) > /dev/null 2>&1


    ( rm results/0066_getSNPs_from_BAM_by_bcftools/tmp/lists/*.* ) > /dev/null 2>&1
    total_lines=$(wc -l < "$list")
    lines_per_part=$(( $total_lines / 10 ))
    split -l "$lines_per_part" -a 3 -d "$list" list.assembly_fastq.txt_
    mv list.assembly_fastq.txt_* results/0066_getSNPs_from_BAM_by_bcftools/tmp/lists/
###############################################################################
## create and submit sbatch

    for sublist in $( ls results/0066_getSNPs_from_BAM_by_bcftools/tmp/lists/ ); do 
        echo "creating sbatch for $sublist, and submitting"
        sed "s/ABC/$sublist/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0066_getSNPs_from_BAM_by_bcftools.sbatch \
        | sed "s|JKL|$fasta_path|g" | sed "s|XYZ|$fastq_path|g" \
        > results/0066_getSNPs_from_BAM_by_bcftools/tmp/sbatch/0066_getSNPs_from_BAM_by_bcftools.$sublist.sbatch
        sbatch results/0066_getSNPs_from_BAM_by_bcftools/tmp/sbatch/0066_getSNPs_from_BAM_by_bcftools.$sublist.sbatch
    done

    number_of_sublist=$(ls results/0066_getSNPs_from_BAM_by_bcftools/tmp/lists/list.assembly_fastq.txt_* | wc -l)
    while [ "$number_of_sublist" != "$number_of_sublist_finished" ]; do
        sleep 300
        number_of_sublist_finished=$( grep -c "The run for sublist :" results/0066_getSNPs_from_BAM_by_bcftools/tmp/slurm/*.out.0066_getSNPs_from_BAM_by_bcftools.txt  | wc -l )
        echo "$number_of_sublist_finished/$number_of_sublist finished by now, waiting for 5 min" 
    done 

###############################################################################
## footer
    end_time=$(date +"%Y%m%d_%H%M%S")
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/time_calculations.sh "$start_time" "$end_time"
###############################################################################