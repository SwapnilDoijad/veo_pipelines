#!/bin/bash
###############################################################################
echo "script 0060_QC_genome-metagenome_assembly_by_metaquast started ---------------------"
###############################################################################
## step-00: preparation 

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		read l
		list=$(echo "list.$l.txt")
	fi
    
    ## find assembly directories
    number_of_metagenome_assembly_directories=$(find results/ -type d -name "*_metagenome_*" | wc -l )
    metagenome_assembly_directories=$(find results/ -type d -name "*_metagenome_*")

	(mkdir -p results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta ) > /dev/null 2>&1

###############################################################################
## step-01: copy data

    if [ ! -d results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta ] ; then 
    for i in $(cat $list); do  

        ( mkdir -p results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta/$i ) > /dev/null 2>&1

        if [ -d results/0051_metagenome_assembly_by_canu/raw_files/ ] ; then 
            if [ -f results/0051_metagenome_assembly_by_canu/raw_files/$i/$i.contigs.fasta ] ; then
                ( cp results/0051_metagenome_assembly_by_canu/raw_files/$i/$i.contigs.fasta \
                results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta/$i/canu.$i.fasta ) > /dev/null 2>&1
                else
                echo "results/0051_metagenome_assembly_by_canu/raw_files/$i/$i.contigs.fasta not available"
            fi
        fi 

        if [ -d results/0052_metagenome_assembly_by_fly/raw_files/ ] ; then 
            if  [ -f results/0052_metagenome_assembly_by_fly/raw_files/$i/assembly.fasta ] ; then
                ( cp results/0052_metagenome_assembly_by_fly/raw_files/$i/assembly.fasta \
                results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta/$i/fly.$i.fasta ) > /dev/null 2>&1
                else
                echo "results/0052_metagenome_assembly_by_fly/raw_files/$i/assembly.fasta not available" 
            fi
        fi 

        if [ -d results/0053_metagenome_assembly_by_raven/raw_files/ ] ; then 
            if [ -f results/0053_metagenome_assembly_by_raven/raw_files/$i.fasta ]; then 
                ( cp results/0053_metagenome_assembly_by_raven/raw_files/$i.fasta \
                results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta/$i/raven.$i.fasta ) > /dev/null 2>&1
                else
                echo "results/0053_metagenome_assembly_by_raven/raw_files/$i.fasta not available"
            fi
        fi

    done 
    fi 

###############################################################################
## step-02: run metaquast
    
    for i in $(cat $list); do  
        if [ ! -d results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta/$i ] ; then 
            echo "metaquast for $i: running"
            python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
            -o results/0060_QC_genome-metagenome_assembly_by_metaquast/results/$i \
            results/0060_QC_genome-metagenome_assembly_by_metaquast/all_fasta/$i/* 
            else
            echo "metaquast for $i: already finished"
        fi
    done 

    # for i in $(cat $list); do  
    #     if [ ! -f results/0060_QC_genome-metagenome_assembly_by_metaquast/results/$i.zip ] ; then 
    #         echo "compressing metaquast output for $i"
    #         zip -r results/0060_QC_genome-metagenome_assembly_by_metaquast/results/$i.zip \
    #         results/0060_QC_genome-metagenome_assembly_by_metaquast/results/$i/
    #         else
    #         echo "compressing metaquast output for $i : already finished"
    #     fi 
    # done 

###############################################################################
## step-03: send report by email (with attachment)

    echo "sending email"
    user=$(whoami)
    #user_name=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $2}' | | awk '{print $1}')
    user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python3.6 \
    /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0060_QC_combine_fastq_QC_by_metaquast.py -e $user_email

    deactivate
###############################################################################
echo "script 0060_QC_genome-metagenome_assembly_by_metaquast ended -----------------------"
###############################################################################