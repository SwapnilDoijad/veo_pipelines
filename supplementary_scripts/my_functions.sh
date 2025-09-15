#!/bin/bash
source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
wd="results/$pipeline"
raw_files="$wd/raw_files"
pn=$(echo $pipeline | awk -F'_' '{print $1}' ) # pipeline number
## paths
yq="/home/groups/VEO/tools/yq/v4.42.1/yq"
suppl_scripts="/home/groups/VEO/scripts_for_users/supplementary_scripts"
utilities="/home/groups/VEO/scripts_for_users/supplementary_scripts/utilities"
plots="/home/groups/VEO/scripts_for_users/supplementary_scripts/plots"
tools="/home/groups/VEO/tools"
scripts_for_users_path="/home/groups/VEO/scripts_for_users"
parameters="tmp/parameters/$pipeline.*"
files_in_data_directory="tmp/parameters/files_in_data_directory.txt"
resource_log="$wd/tmp/resource_log"

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
            # echo "creating list file based on the files in data folder"
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

number_of_users() {
    squeue | awk '{print $4}' | sort | uniq -c 
}

number_of_jobs() {
    squeue | wc -l
}

# Function to count reads in a FASTQ.gz or FASTQ file
count_reads_from_fastq() {
    local fastqFile="$1"
    
    if [[ ! -f "$fastqFile" ]]; then
        echo "fastqFile_absent!"
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
        echo "fastaFile_absent!"
        return 1
    fi

    local total_number_of_sequences=$(grep -c "^>" "$fastaFile")

    echo "$total_number_of_sequences"

}

# Function to get individual sequence length of all sequences in FASTA 
get_fasta_lengths() {
    local fasta_file="$1"
    awk '/^>/ {
        if (seqlen) { print seqlen }
        print
        seqlen=0
        next
    } 
    {
        seqlen += length($0)
    } 
    END {
        if (seqlen) print seqlen
    }' "$fasta_file"
}

get_suffix() {
    case "$1" in
        *.fastq.gz) echo ".fastq.gz" ;;
        *.fq.gz) echo ".fq.gz" ;;
        *.fastq) echo ".fastq" ;;
        *.txt) echo ".txt" ;;
        *) echo "unknown" ;;
    esac
}

# Function to get accumulated length of all sequences in FASTA
fasta_length() {
    local fasta_file="$1"
    awk '/^>/ { next } { total_length += length($0) } END { print total_length }' "$fasta_file"
}

get_fasta_contigs_length_individual() {
    local fasta_file="$1"

    if [[ ! -f "$fasta_file" ]]; then
        echo "Error: FASTA file not found!"
        return 1
    fi

    awk '/^>/ {
        if (seqlen) { 
            print contig_name, seqlen 
        }
        contig_name = substr($0, 2)  # Remove the ">" from the contig name
        seqlen = 0
        next
    } 
    {
        seqlen += length($0)
    } 
    END {
        if (seqlen) {
            print contig_name, seqlen
        }
    }' "$fasta_file"
}

get_fasta_contigs_length_all() {
    local fasta_file="$1"

    if [[ ! -f "$fasta_file" ]]; then
        echo "Error: FASTA file not found!"
        return 1
    fi

    # Extract the file ID by removing the last dot and everything after it
    local file_id=$(basename "$fasta_file" | sed 's/\.[^.]*$//')

    awk -v file_id="$file_id" '
    BEGIN {
        total_contigs = 0;
        total_length = 0;
    }
    /^>/ {
        total_contigs++;
        if (seqlen) {
            total_length += seqlen;
        }
        seqlen = 0;
        next;
    }
    {
        seqlen += length($0);
    }
    END {
        if (seqlen) {
            total_length += seqlen;
        }
        print file_id, total_contigs, total_length;
    }' "$fasta_file"
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
    
    if [ "$total_lines" -ge 1 ]  && [ "$total_lines" -le 2 ]; then 
        lines_per_part=$(( total_lines / 1 ))
        split -d -a 3 -l "$lines_per_part" "$list" "$wd/tmp/lists/list.$pipeline_id"_
        elif [ "$total_lines" -ge 3 ] && [ "$total_lines" -le 6 ]; then
        lines_per_part=$(( total_lines / 2 ))
        split -d -a 3 -l "$lines_per_part" "$list" "$wd/tmp/lists/list.$pipeline_id"_
        elif [ "$total_lines" -ge 6 ] && [ "$total_lines" -le 10 ]; then
        lines_per_part=$(( total_lines / 5 ))
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
    mkdir -p "$1"/tmp/resource_log > /dev/null 2>&1
    cp tmp/parameters/$pipeline.* "$wd"/tmp/ > /dev/null 2>&1
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
        job_id=$(sbatch "$wd"/tmp/sbatch/"$pipeline.$sublist.sbatch" | awk '{print $4}')
        log "SUBMITTED : $pipeline : sbatch for $sublist : $job_id"
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
            sleep 15
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
        sleep 15
        size2=$(stat -c %s "$file")
        if [ "$size1" -eq "$size2" ]; then
            break
        fi
    done
    
    echo "File '$file' is completely written"
}

## wait_till_all_job_finished_with_name my_job_name
wait_till_all_job_finished_with_name() {
    local job_name=$1

    if [ -z "$job_name" ]; then
        echo "Job name must be provided."
        return 1
    fi

    while true; do
        sleep 10
        # Using squeue with the --user option to filter jobs by the current user
        job_exists=$(squeue --user "$(whoami)" | grep "$job_name")
        
        if [ -z "$job_exists" ]; then
            echo "All jobs with name $job_name have finished."
            break
        else
            echo "Waiting for jobs with name $job_name to finish..."
        fi
    done
}


# Function to check the exit status of the last command
check_status() {
    local status=$?   # Capture the exit status of the last command
    local message="$1" # Accept a custom message as a parameter
    
    if [ $status -eq 0 ]; then
        log "SUCCESS: $message"
    else
        log "ERROR: $message (Exit status: $status)"
        exit $status # Exit the script with the error status
    fi
}

# Example usage:
# Replace 'your_job_script.sbatch' with your actual SLURM job script
# submit_sbatch_and_wait_till_run_is_complete "your_job_script.sbatch"
submit_sbatch_and_wait_till_run_is_complete() {
    local job_script="$1"

    # Validate input
    if [[ -z "$job_script" ]]; then
        echo "Error: Please provide the SLURM job script."
        return 1
    fi

    # Submit the job and capture the Job ID
    local job_id
    job_id=$(sbatch "$job_script" | awk '{print $NF}')

    if [[ -z "$job_id" ]]; then
        echo "Error: Failed to submit the job."
        return 1
    fi

    echo "Job submitted with ID: $job_id"

    # Check job status in a loop
    while true; do
        # Query the job's status
        local job_status
        job_status=$(squeue --job "$job_id" 2>/dev/null | tail -n +2)

        if [[ -z "$job_status" ]]; then
            # If no output, the job is completed or no longer in the queue
            echo "Job $job_id has completed."
            break
        else
            # Job is still running or pending
            echo "Job $job_id is still running. Waiting 60 seconds..."
            sleep 60
        fi
    done
}

# clean_empty_files_and_dirs -i /path/to/directory
clean() {
    # find "$wd" -type f -empty -delete
    # find "$wd" -type d -empty -delete
    rm -rf tmp.best_free_nodes_at_draco.txt > /dev/null 2>&1
    ## send email notification
        user=$(whoami)
        user_name=$(grep $user $suppl_scripts/user_email.csv | awk -F'\t' '{print $2}')
        # user_email=$(grep $user $suppl_scripts/user_email.csv | awk -F'\t' '{print $3}')

        sed "s/my_user/$user/g" $suppl_scripts/emails/general_log.py \
        | sed "s/my_pipeline/$pipeline/g" | sed "s|my_dir|$wd|g" \
        | sed "s/user_name/$user_name/g" | sed "s|my_jobid|$SLURM_JOB_ID|g" > tmp/$user.$SLURM_JOB_ID.general_log.py

        source /home/groups/VEO/tools/email/myenv/bin/activate
        python tmp/$user.$SLURM_JOB_ID.general_log.py
        deactivate
        rm -rf tmp/$user.$SLURM_JOB_ID.general_log.py
}

## log_usage
log_usage() {
    local pid="$1"
    local log_file="$2"
    local num_cores=$(nproc)

    echo -e "Timestamp\tCPU(%)\tMemory(MB)\tCPUs_used\tGPU(%)\tGPU_Mem(MB)" > "$log_file"

    while kill -0 "$pid" 2>/dev/null; do
        # Get CPU and memory usage
        ps_output=$(ps -p "$pid" -o %cpu,rss --no-headers)
        cpu_usage=$(echo "$ps_output" | awk '{print $1}')
        mem_usage=$(echo "$ps_output" | awk '{print $2}')
        mem_usage_mb=$(echo "scale=2; $mem_usage / 1024" | bc)
        cpus_used=$(echo "scale=2; $cpu_usage * $num_cores / 100" | bc)

        # Get GPU usage (handle cases where NVIDIA GPU is not present)
        gpu_output=$(nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null)
        if [ -n "$gpu_output" ]; then
            gpu_usage=$(echo "$gpu_output" | awk -F ',' '{print $1}')
            gpu_mem=$(echo "$gpu_output" | awk -F ',' '{print $2}')
        else
            gpu_usage="0"
            gpu_mem="0"
        fi

        # Append data to log file with updated timestamp format (underscores instead of spaces)
        echo -e "$(date '+%Y-%m-%d_%H:%M:%S')\t$cpu_usage\t$mem_usage_mb\t$cpus_used\t$gpu_usage\t$gpu_mem" | sed 's/No\ devices\ were\ found/0/g' >> "$log_file"

        sleep 1
    done
}

summarize_log() {
    local log_file="$1"

    # Create a blank summary file to avoid overwriting
    local summary_file="$(dirname "$log_file")/$(basename "$log_file" .tsv).summary.tsv"
    : > "$summary_file"  # This creates or clears the file

    # Extract start time and end time from the log file, replacing underscores with spaces for correct date parsing
    local start_time=$(awk 'NR==2 {print $1}' "$log_file" | sed 's/_/ /g')  # Replace underscore with space
    local end_time=$(awk 'END {print $1}' "$log_file" | sed 's/_/ /g')    # Replace underscore with space

    # Ensure the timestamp is in a recognizable format for date parsing (e.g., 2025-02-15 09:13:00)
    start_time=$(echo "$start_time" | sed 's/_/ /g')  # Ensure correct formatting
    end_time=$(echo "$end_time" | sed 's/_/ /g')      # Ensure correct formatting

    # Calculate runtime in seconds
    local start_epoch=$(date -d "$start_time" '+%s')
    local end_epoch=$(date -d "$end_time" '+%s')
    local runtime_seconds=$((end_epoch - start_epoch))

    # Calculate the runtime in HH:MM:SS format
    local hours=$((runtime_seconds / 3600))
    local minutes=$(((runtime_seconds % 3600) / 60))
    local seconds=$((runtime_seconds % 60))
    local runtime_hms=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)

    # Use awk to calculate summary stats and write to a summary file
    awk -v start="$start_time" -v end="$end_time" -v runtime_hms="$runtime_hms" '
    BEGIN {
        OFS="\t";
        print "Summary", "CPU(%)", "Memory(MB)", "CPUs_used", "GPU(%)", "GPU_Mem(MB)";
    }
    NR > 1 {
        # Skip the header row and rows with invalid data
        if ($2 == "N/A" || $2 == "") next;  # Skip rows where CPU is invalid or zero
        cpu_sum += $2;
        mem_sum += $3;
        cpus_used_sum += $4;

        # Track GPU data
        if ($5 != "N/A") gpu_sum += $5;  # Only include valid GPU data for average
        if ($6 != "N/A") gpu_mem_sum += $6;  # Only include valid GPU memory data
        if (NR == 2 || $5 < gpu_min) gpu_min = $5;  # Calculate Min for GPU(%) usage
        if (NR == 2 || $5 > gpu_max) gpu_max = $5;  # Calculate Max for GPU(%) usage
        if (NR == 2 || $6 < gpu_mem_min) gpu_mem_min = $6;  # Calculate Min for GPU memory usage
        if (NR == 2 || $6 > gpu_mem_max) gpu_mem_max = $6;  # Calculate Max for GPU memory usage

        # Calculate Min/Max for CPU and memory
        if (NR == 2 || $2 < cpu_min) cpu_min = $2;
        if (NR == 2 || $2 > cpu_max) cpu_max = $2;

        if (NR == 2 || $3 < mem_min) mem_min = $3;
        if (NR == 2 || $3 > mem_max) mem_max = $3;

        if (NR == 2 || $4 < cpus_min) cpus_min = $4;
        if (NR == 2 || $4 > cpus_max) cpus_max = $4;

        count++;
    }
    END {
        # Calculate averages
        cpu_avg = cpu_sum / count;
        mem_avg = mem_sum / count;
        cpus_used_avg = cpus_used_sum / count;

        if (count > 0) {
            gpu_avg = gpu_sum / count;
            gpu_mem_avg = gpu_mem_sum / count;
        } else {
            gpu_avg = "N/A";
            gpu_mem_avg = "N/A";
        }

        # Print summary
        print "Average", cpu_avg, mem_avg, cpus_used_avg, gpu_avg, gpu_mem_avg;
        print "Min", cpu_min, mem_min, cpus_min, gpu_min, gpu_mem_min;
        print "Max", cpu_max, mem_max, cpus_max, gpu_max, gpu_mem_max;
        print "";
        print "Process Start Time:", start;
        print "Process End Time:", end;
        print "Total Runtime (HH:MM:SS):", runtime_hms;
    }' "$log_file" > "$summary_file"

    # echo "Summary written to summary.$log_file"
}

## log_usage
get_resource_stat() {
    local pid="$1"
    local log_file="$2"

    # Log resource usage for the process in the background
    log_usage "$pid" "$log_file" & usage_pid=$!

    # Wait for both the Python script and the log function to complete
    wait "$pid"
    wait "$usage_pid"

    # Summarize the log file
    summarize_log "$log_file"
}

report() {
  local user_id="$USER"
  local job_name="$pipeline"
  local wd="results/${pipeline}"

  local job_count
  while :; do
    job_count=$(squeue --noheader -u "$user_id" -n "$job_name" -o "%i" | wc -l)
    if [ "$job_count" -le 1 ]; then
      echo "Now only $job_count job(s) with name '$job_name' remain for user '$user_id'."
      break
    fi
    echo "More than one job with name '$job_name' running for user '$user_id'. Waiting for one minute..."
    sleep 60
  done

  # Optional: check input file
  if [ ! -f "$wd/summary.tsv" ]; then
    echo "ERROR: Input file not found: $wd/summary.tsv" >&2
    return 1
  fi

    source /home/groups/VEO/tools/biopython/myenv/bin/activate
    python "$suppl_scripts/report_file/${pipeline}.report.py" \
        -i "$wd/summary.tsv" \
        -o "$wd/report.pdf"
    deactivate

    if [ -f "$wd/report.pdf" ]; then
        user=$(whoami)
        user_name=$(grep $user $suppl_scripts/user_email.csv | awk -F'\t' '{print $2}')
        user_email=$(grep $user $suppl_scripts/user_email.csv | awk -F'\t' '{print $3}')

        source /home/groups/VEO/tools/email/myenv/bin/activate
            python "$suppl_scripts/emails/report.py" \
            -e ${user_email} \
            -p ${pipeline} \
            -w ${wd}
        deactivate
    fi

}

log "$pipeline : $(whoami) : $(hostname)" >> /vast/groups/VEO/.veo_pipeline_usage.log

