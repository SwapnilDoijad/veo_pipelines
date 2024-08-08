#!/bin/bash
###############################################################################
## step-01: identify type of data and path of data present
    user_id=$(whoami)
    user_name=$( grep $user_id /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv  | awk -F' ' '{ print $2}' )
    user_email=$( grep $user_id /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t' '{ print $3}' )
    echo "-------------------------------------------------------------------------"
    if [ ! -z $user_name ] ; then
        echo "Hey $user_name ($user_id, $user_email) !!!"
        echo "You will receive the notification emails for the start and end of the job"
        echo "for any problems contact swapnil.doijad@gmail.com"
        else
        echo "Hey $user_name ($user_id) !!!"
        echo "for any problems contact swapnil.doijad@gmail.com"
    fi

    echo "-------------------------------------------------------------------------"
    fasta_file_path=$( find -type f -name "*.fasta" | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' |  sed 's/^..//' | sed 's/.$//' | sort -u | grep -v "results/0040_assembly/all_fasta" )
    fastq_file_path=$( find -type f -name "*.fastq.gz"  | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' |  sed 's/^..//' | sed 's/.$//' | sort -u | grep -v "data/illumina/raw_reads" )
    echo "-------------------------------------------------------------------------"
    if [ ! -z fasta_file_path ]; then
        fasta_file_count=$(ls $fasta_file_path | wc -l)
        test_fasta_file=$(ls $fasta_file_path/ | head -1 )
        fasta_file_length=$(cat $fasta_file_path/$test_fasta_file | wc -c)
        if [[ $fasta_file_length -gt 500000 ]]; then
            type_of_files=bacterial_fasta
            else
            type_of_files=prophage_fasta
        fi
        echo "$fasta_file_count $type_of_files files found at $fasta_file_path"
    fi

    if [ ! -z fastq_file_path ]; then
        fastq_file_count=$(ls $fastq_file_path | wc -l)
        echo "$fastq_file_count fastq.gz (raw_read) files found at $fastq_file_path"
    fi
    echo "-------------------------------------------------------------------------"

###############################################################################
## step-2: get pipeline
    ls /home/groups/VEO/scripts_for_users/*.sh | awk -F'/' '{print $NF}'
    echo ""
    echo "which pipeline you would like to run (provide only the number)?"
    echo "for e.g. to run fastANI type 0041 (and press enter)"
    read pipeline_number
    pipeline=$(ls /home/groups/VEO/scripts_for_users/"$pipeline_number"*)
    pipeline_id=$(ls /home/groups/VEO/scripts_for_users/"$pipeline_number"* | awk -F'/'  '{print $NF}' | sed 's/\.sh//g' )
    echo "-------------------------------------------------------------------------"
###############################################################################
## step-4: create a list file
    if [ "$type_of_files" == bacterial_fasta ] ; then
        #echo "$fasta fasta found, writing list.my_bacterial_fasta.txt file"
        (ls $fasta_file_path | awk -F'/' '{print $NF}'| sed 's/\.fasta//g' | sort -u > list.bacterial_fasta.txt ) > /dev/null 2>&1
    fi

    if [ "$type_of_files" == prophage_fasta ] ; then
        #echo "$fasta fasta found, writing list.my_prophage_fasta.txt file"
        (ls $fasta_file_path | awk -F'/' '{print $NF}'| sed 's/\.fasta//g' | sort -u > list.propahge_fasta.txt ) > /dev/null 2>&1
    fi

    if [ "$fastq_file_count" -ne 0 ] ; then
        #echo "$fasta fasta found, writing list.my_fastq.txt file"
        (ls $fastq_file_path | awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' | awk -F'_' '{print $1}' | sort -u > list.fastq.txt ) > /dev/null 2>&1
    fi

###############################################################################
## step-5: create a sbatch file
    echo $pipeline > /home/groups/VEO/scripts_for_users/supplementary_scripts/tmp.txt
    cat /home/groups/VEO/scripts_for_users/supplementary_scripts/template.sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/tmp.txt > /home/groups/VEO/scripts_for_users/supplementary_scripts/tmp.sbatch
    sed -i "s/your_email@example.com/$user_email/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/tmp.sbatch
    sed -i "s/slurmenv/'$pipeline_id'/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/tmp.sbatch
###############################################################################
## step-6: run sbatch file
    # Submit the sbatch command and capture the job ID
    job_id=$(sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/tmp.sbatch | awk '{print $NF}')

    # Check the status of the submitted job
    job_status=$(squeue -j $job_id -h -o "%T")

    # Loop until the job completes
    while [ ! -z "$job_status" ]; do
        echo $pipeline_id $job_id $job_status 
        sleep 60 # Sleep for 1 minute
        job_status=$(squeue -j $job_id -h -o "%T")
    done

###############################################################################
exit
