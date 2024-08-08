#!/bin/bash

source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
wd=results/$pipeline
raw_files=$wd/raw_files
pn=$(echo $pipeline | awk -F'_' '{print $1}' ) # pipeline number
## paths
yq=/home/groups/VEO/tools/yq/v4.42.1/yq
suppl_scripts="/home/groups/VEO/scripts_for_users/supplementary_scripts"
my_tool_path="/home/groups/VEO/tools"
scripts_for_users_path="/home/groups/VEO/scripts_for_users"
parameters="tmp/parameters/$pipeline.*"
files_in_data_directory="tmp/parameters/files_in_data_directory.txt"

if [ -f tmp/parameters/$pipeline.txt ]; then 
    fasta_dir_path=$(grep "my_fasta_dir" tmp/parameters/$pipeline.txt | awk '{print $NF}')
    fastq_dir_path=$(grep "my_fasta_dir" tmp/parameters/$pipeline.txt | awk '{print $NF}')
fi

if [ -e "$files_in_data_directory" ] ; then 
    data_directory_fastq_path=$( grep -w "fastq" $files_in_data_directory | awk '{print $NF}' )
    data_directory_fasta_path=$( grep -w "fasta" $files_in_data_directory | awk '{print $NF}' )
    data_directory_pod5_path=$( grep -w "pod5" $files_in_data_directory | awk '{print $NF}' )
fi

if [ ! -f list.fastq.txt ]; then
    if [ ! -f list.fasta.txt ] ; then 
        if [ ! -f list.pod5.txt ] ; then 
            ## create list files
            # echo "--------------------------------------------------------------------------------"
            # echo "list.fasta.txt / list.fastq.txt / list.pod5.txt not available"
            echo "creating list file based on the files in data folder"
            if [ -n "$data_directory_fastq_path" ]; then
                ls $data_directory_fastq_path | awk -F'_' '{print $1}' | sed 's/.fastq.gz//g' | sort -u > list.fastq.txt
                list=list.fastq.txt
                elif [ -n "$data_directory_fasta_path" ] ; then 
                ls "$data_directory_fasta_path" | awk -F'_' '{print $1}' | sed 's/.fasta//g' | sort -u > list.fasta.txt
                list=list.fasta.txt
                elif [ -n "$data_directory_fasta_path" ] ; then 
                ls "$data_directory_fasta_path" | awk -F'_' '{print $1}' | sed 's/.pod5//g' | sort -u > list.pod5.txt
                list=list.pod5.txt
            fi
            else 
            list=list.pod5.txt
        fi
        else
        list=list.fasta.txt
    fi
    else
    list=list.fastq.txt
fi 


log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1"
}

# Function to count reads in a FASTQ.gz or FASTQ file
count_reads_from_fastq() {
    local fastqFile="$1"
    
    if [[ ! -f "$fastqFile" ]]; then
        echo "fastqFile not found!"
        return 1
    fi

    local lines

    # Check if the file is gzipped or not
    if [[ "$fastqFile" == *.gz ]]; then
        # Count lines in a gzipped FASTQ file
        lines=$(pigz -dc "$fastqFile" | wc -l)
    else
        # Count lines in a plain FASTQ file
        lines=$(wc -l < "$fastqFile")
    fi

    # Calculate the total number of reads
    local total_number_of_reads=$((lines / 4))

    # Output the total number of reads
    echo "$total_number_of_reads"
}

# Function to count reads in a FASTA file
count_number_of_sequences_in_fasta() {
    local fastaFile="$1"

    if [[ ! -f "$fastaFile" ]]; then
        echo "fastaFile not found!"
        return 1
    fi

    local total_number_of_sequences=$(grep -c "^>" "$fastaFile")

    echo "$total_number_of_sequences"

}


# Function to check if the files exist
barcode_files_exist() {
    if [ -f "tmp/parameters/0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu.barcode.txt" ] && [ -f "tmp/parameters/0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu.barcode_corresponding_ids.txt" ]; then
        return 0
    else
        return 1
    fi
}


# Function to count the number of currently running jobs
count_running_jobs() {
    squeue -u $USER | wc -l
}


## split_list 
split_list() {
    local wd="$1"
    local list="$2"

    ( rm $wd/tmp/lists/*.* ) > /dev/null 2>&1
    
    pipeline_id=$(echo "$wd" | awk -F'/' '{print $2}')
    total_lines=$(wc -l < "$list")
    
    if [ "$total_lines" -ge 1 ]  && [ "$total_lines" -le 5 ]; then 
        lines_per_part=$(( total_lines / 1 ))
        split -d -a 3 -l "$lines_per_part" "$list" "$wd/tmp/lists/list.$pipeline_id"_
        elif [ "$total_lines" -ge 6 ] && [ "$total_lines" -le 10 ]; then
        lines_per_part=$(( total_lines / 2 ))
        split -d -a 3 -l "$lines_per_part" "$list" "$wd/tmp/lists/list.$pipeline_id"_
        elif [ "$total_lines" -ge 11 ] && [ "$total_lines" -le 50 ]; then
        lines_per_part=$(( total_lines / 5 ))
        split -d -a 3 -l "$lines_per_part" "$list" "$wd/tmp/lists/list.$pipeline_id"_
        elif [ "$total_lines" -ge 51 ] && [ "$total_lines" -le 100 ]; then
        lines_per_part=$(( total_lines / 10 ))
        split -d -a 3 -l "$lines_per_part" "$list" "$wd/tmp/lists/list.$pipeline_id"_
        elif [ "$total_lines" -ge 101 ] ; then
        lines_per_part=$(( total_lines / 10 ))
        split -d -a 3 -l "$lines_per_part" "$list" "$wd/tmp/lists/list.$pipeline_id"_
    else
        cp "$list" "$wd/tmp/lists/list.$pipeline_id"_001
    fi
}

## split_list
create_directories_structure_1() {
    mkdir -p "$1"/raw_files > /dev/null 2>&1
    mkdir -p "$1"/tmp/slurm > /dev/null 2>&1
    mkdir -p "$1"/tmp/sbatch > /dev/null 2>&1
    mkdir -p "$1"/tmp/lists > /dev/null 2>&1
}

## submit jobs 
## submit_jobs "/your/working/directory" "your_pipeline"
submit_jobs() {
    local wd="$1"
    local pipeline="$2"

    for sublist in "$wd"/tmp/lists/*; do
        sublist=$(basename "$sublist")
        sed "s#ABC#$sublist#g" "/home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch" \
        > "$wd"/tmp/sbatch/"$pipeline.$sublist.sbatch"
        sbatch "$wd"/tmp/sbatch/"$pipeline.$sublist.sbatch" > /dev/null 2>&1
        log "SUBMITTED : $pipeline : sbatch for $sublist"
    done
}

## wait for file existence and completion
## wait_for_file_existence_and_completion "/path/to/your/file.txt"
wait_for_file_existence_and_completion() {
    local file_path="$1"

    # Wait until the file exists
    while [ ! -e "$file_path" ]; do
        echo "WAITING : $i : to be created... "
        sleep 10
    done

    # Wait until the file stops growing
    local initial_size=$(stat -c %s "$file_path")
    while true; do
        local current_size=$(stat -c %s "$file_path")
        if [ $current_size -eq $initial_size ]; then
            log "FINISHED : $i : written "
            break
        else
            log "WAITING : $i : to be written..."
            sleep 10
            initial_size=$current_size
        fi
    done
}


# Function to check the number of running jobs and wait if more than the specified number
## e.g., wait_for_jobs_to_complete 100
wait_for_jobs_to_complete() {
  local max_jobs=$1
  local running_jobs=$(squeue -u $USER | wc -l)
  
  while [ "$running_jobs" -gt "$max_jobs" ]; do
    echo "More than $max_jobs jobs running. Waiting..."
    sleep 10
    running_jobs=$(squeue -u $USER | wc -l)
  done
}


## wait till file is complete written
wait_until_written() {
    local file="$1"
    local wait_time=10
    local max_attempts=$((3 * 60 * 60 / $wait_time))  # Maximum 3 hours (in seconds)

    # Check if file exists
    local attempts=0
    while [ ! -f "$file" ]; do
        if [ "$attempts" -eq "$max_attempts" ]; then
            echo "Maximum wait time reached. File '$file' not found."
            exit 1
        fi
        echo "File '$file' not found. Waiting $wait_time seconds..."
        sleep $wait_time
        ((attempts++))
    done

    # Use inotifywait to monitor file events
    while inotifywait -q -e close_write "$file" >/dev/null 2>&1; do
        # Check if file size remains constant for a short period (indicating it's completely written)
        size1=$(stat -c %s "$file")
        sleep 1
        size2=$(stat -c %s "$file")
        if [ "$size1" -eq "$size2" ]; then
            break
        fi
    done
    
    echo "File '$file' is completely written"
}


## wait_till_all_job_finished my_job_name
wait_till_all_job_finished() {
    local job_name=$1

    if [ -z "$job_name" ]; then
        echo "Job name must be provided."
        return 1
    fi

    while true; do
        # Using squeue with the --user option to filter jobs by the current user
        job_exists=$(squeue --user "$(whoami)" | grep "$job_name")
        
        if [ -z "$job_exists" ]; then
            echo "All jobs with name $job_name have finished."
            break
        else
            echo "Waiting for jobs with name $job_name to finish..."
            sleep 5  # Wait for 5 seconds before checking again
        fi
    done
}

