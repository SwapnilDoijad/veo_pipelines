#!/bin/bash
###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : 0040_genome_assembly_QC_by_metaquast ----------------------------------"
###############################################################################
## step-00: preparation 

    wd=results/0040_genome_assembly_QC_by_metaquast

    if [ -f list.fastq.txt ]; then 
        list=list.fastq.txt
		else
		echo "provide list file (for e.g. all)"
		read l
		list=$(echo "list.$l.txt")
	fi
    
    ## find assembly directories
    number_of_genome_assembly_directories=$(find results/ -type d -name "*_genome_*" | wc -l )
    genome_assembly_directories=$(find results/ -type d -name "*_genome_*")

	(mkdir -p $wd/all_fasta ) > /dev/null 2>&1

###############################################################################
## step-01: copy data

    for i in $(cat $list); do  
        if [ ! -d $wd/all_fasta/$i ] ; then 

            ( mkdir -p $wd/all_fasta/$i ) > /dev/null 2>&1

            ## 0043 unicycler
            if [ -d results/0043_genome_assembly_by_unicycler/raw_files/ ] ; then 
                if [ -f results/0043_genome_assembly_by_unicycler/raw_files/$i/assembly.fasta ] ; then
                    ( cp results/0043_genome_assembly_by_unicycler/raw_files/$i/assembly.fasta \
                    $wd/all_fasta/$i/unicycler.$i.fasta ) > /dev/null 2>&1
                    else
                    echo "results/0043_genome_assembly_by_unicycler/raw_files/$i/assembly.fasta not available"
                fi
            fi 

            ## 0045 canu
            if [ -d results/0045_genome_assembly_by_canu/raw_files/ ] ; then 
                if [ -f results/0045_genome_assembly_by_canu/raw_files/$i/$i.contigs.fasta ]; then 
                    ( cp results/0045_genome_assembly_by_canu/raw_files/$i/$i.contigs.fasta \
                    $wd/all_fasta/$i/canu.$i.fasta ) > /dev/null 2>&1
                    else
                    echo "results/0045_genome_assembly_by_canu/raw_files/$i/$i.contigs.fasta not available"
                fi
            fi

            ## 0048 fly
            if [ -d results/0048_genome_assembly_by_flye/raw_files/ ] ; then 
                if  [ -f results/0048_genome_assembly_by_flye/raw_files/$i/assembly.fasta ] ; then
                    ( cp results/0048_genome_assembly_by_flye/raw_files/$i/assembly.fasta \
                    $wd/all_fasta/$i/flye.$i.fasta ) > /dev/null 2>&1
                    else
                    echo "results/0048_genome_assembly_by_flye/raw_files/$i/assembly.fasta not available" 
                fi
            fi 

        fi 

    done 

###############################################################################
## step-02: run metaquast
    
    for i in $(cat $list); do  
        if [ ! -d $wd/results/$i ] ; then 
            echo "metaquast for $i: running"
            python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
            -o $wd/results/$i \
            $wd/all_fasta/$i/* 
            else
            echo "metaquast for $i: already finished"
        fi
    done 

    # for i in $(cat $list); do  
    #     if [ ! -f $wd/results/$i.zip ] ; then 
    #         echo "compressing metaquast output for $i"
    #         zip -r $wd/results/$i.zip \
    #         $wd/results/$i/
    #         else
    #         echo "compressing metaquast output for $i : already finished"
    #     fi 
    # done 

###############################################################################
## step-03: send report by email (with attachment)

    # echo "sending email"
    # user=$(whoami)
    # #user_name=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $2}' | | awk '{print $1}')
    # user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    # source /home/groups/VEO/tools/email/myenv/bin/activate

    # python3.6 \
    # /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0060_QC_combine_fastq_QC_by_metaquast.py -e $user_email

    # deactivate
###############################################################################
	log "ENDED : 0040_genome_assembly_QC_by_metaquast ----------------------------------"
###############################################################################