#!/bin/bash
###############################################################################
## header
    start_time=$(date +"%Y%m%d_%H%M%S")
###############################################################################
## step-01: identify the user
    user_id=$(whoami)
    user_name=$( grep $user_id /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv  | awk -F' ' '{ print $2}' )
    user_email=$( grep $user_id /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t' '{ print $3}' )
    echo "-------------------------------------------------------------------------"
    if [ ! -z $user_name ] ; then
        echo "Hey $user_name ($user_id, $user_email), Welcome !!!"
        echo "if you see your email id above, you will receive notifications for your job "
        echo "for any problems contact swapnil.doijad@gmail.com"
        else
        echo "Hey $user_name ($user_id) !!!"
        echo "for any problems contact swapnil.doijad@gmail.com"
    fi
    echo "--------------------------------------------------------------------------------"
    sleep 3 #so that youser can read above comments

###############################################################################
## step-01b: 
    if [ -d data ]; then 
        echo "--------------------------------------------------------------------------------"
        echo "data directory found, looking for files"
        echo "--------------------------------------------------------------------------------"
        ###############################################################################
        ## step-02: identify type of data (fasta/fastq), its path, and rename in unified format to recognise it latter by every script

            ## find path and re-lable pod5 directory
            # echo "looking for pod5 files" 
            pod5_file_path=$(find data/ -type d -name "pod5" | sed 's/\.\///g' )
            if [ ! -z $pod5_file_path ] ; then 
                echo "A pod5 files found at $pod5_file_path"
                echo "------------------------------------------------------------------------------"
                pod5_file_path_count=$( echo $pod5_file_path | tr ' ' '\n' | wc -l )
                if [ $pod5_file_path_count -gt 1 ] ; then 
                    echo "------------------------------------------------------------------------------"
                    echo "      pod5 files found at more than one directory"
                    echo "      "
                    echo $pod5_file_path | tr ' ' '\n' 
                    echo "      "
                    echo "      give one path, for e.g. data/nanopore_4h/pod5, and press enter" 
                    echo "------------------------------------------------------------------------------"
                    read pod5_file_path
                fi
                # else
                # echo "could not locate pod5 files"
            fi

            ## find path and re-lable fastq 
                ## first, find fastq/fastq.gz file if present 
                # echo "looking for fastq or fastq.gz files"
                if [ ! -z $(find data/ -type f \( -name "*.fastq" -o -name "*.fastq.gz" \) | head -1 | awk '{gsub(/\/[^\/]+$/, ""); print}')  ] ; then 
                    echo "fastq files found at data directory"
                    ## renaming 
                    if [ ! -z $(find data/ -type f -name "*.fastq.gz" | head -1 | awk -F'/' '{print $NF}' | grep _1.fastq.gz) ] ; then 
                        for i in $(ls $fastq_file_path/*.fastq.gz | sort -u ) ; do 
                            id=$( echo $i | awk -F'/' '{print $NF}' | awk -F'_' '{print $1}' )
                            echo "renaming $fastq_file_path/"$id"_1.fastq.gz to $fastq_file_path/"$id"_R1_001.fastq.gz"
                            (mv $fastq_file_path/"$id"_1.fastq.gz $fastq_file_path/"$id"_R1_001.fastq.gz) > /dev/null 2>&1
                            echo "renaming $fastq_file_path/"$id"_2.fastq.gz to $fastq_file_path/"$id"_R2_001.fastq.gz"
                            (mv $fastq_file_path/"$id"_2.fastq.gz $fastq_file_path/"$id"_R2_001.fastq.gz) > /dev/null 2>&1
                        done
                    else
                        ## check if fastq files are located in more than one directory 
                        fastq_file_path_number=$( find data/ -type f -name "*.fastq.gz"  | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' | sed 's/.$//' | sort -u | wc -l )
                        if [ "$fastq_file_path_number" -gt 1 ]; then
                            find data/ -type f -name "*.fastq.gz"  | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' | sed 's/.$//' | sort -u 
                            echo "--------------------------------------------------------------------------------"
                            echo "      fastqs are located at more than one path"
                            echo "      please specify which (complete) path to be used"
                            echo "      for e.g."
                            echo "      data/long_reads/raw_reads"
                            echo "--------------------------------------------------------------------------------"
                            read fastq_file_path
                            else
                            fastq_file_path=$( find data/ -type f -name "*.fastq.gz"  | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' | sed 's/.$//' | sort -u )
                        fi

                        if [ ! -z $fastq_file_path ] ; then echo "fastq found at $fastq_file_path" ; fi
                    fi
                    # else
                    # echo "could not locate fastq or fastq.gz files"
                    echo "--------------------------------------------------------------------------------"
                fi

            ## find path and re-label fna
            echo "--------------------------------------------------------------------------------"
            # echo "looking for fna/fasta files in data directory"
                fna=$(find data/ -type f -name "*.fna" | head -1 )
                fna_file_path=$( find data/ -type f -name "*.fna" | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' |  sed 's/^..//' | sed 's/.$//' | sort -u )
                if [ ! -z $fna ] ; then 
                    echo .fna files found at $fna_file_path, renaming them to .fasta
                    for i in $(ls $fna_file_path) ; do 
                        id=$(echo $i | sed 's/\.fna//g')
                        echo "renaming $fna_file_path/$i to $fna_file_path/$i.fasta"
                        mv $fna_file_path/$id.fna $fna_file_path/$id.fasta 
                    done
                fi

            ## find path and re-label fasta
                fasta=$(find data/ -type f -name "*.fasta" | head -1 )
                if [ ! -z $fasta ] ; then 
                    ## check if fasta files are located in more than one directory 
                    fasta_file_path_number=$( find data/ -type f -name "*.fasta" | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' | sed 's/.$//' | sort -u | wc -l )
                        if [ "$fasta_file_path_number" -gt 1 ]; then
                            find data/ -type f -name "*.fasta" | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' | sed 's/.$//' | sort -u 
                            echo "--------------------------------------------------------------------------------"
                            echo "      fastas are located at more than one path"
                            echo "      please specify which (complete) path to be used"
                            echo "      for e.g."
                            echo "      data/my_fasta"
                            echo "      if you are working with the fastq, just press enter (no need to specify any directory)"
                            echo "--------------------------------------------------------------------------------"
                            read fasta_file_path
                            else
                            fasta_file_path=$( find data/ -type f -name "*.fasta" | awk -F'/' '{$NF=""}1' | sed 's/ /\//g' | sed 's/.$//' | sort -u )
                        fi
                    # if [ ! -z $fasta_file_path ] ; then 
                    # echo fasta files found at $fasta_file_path ; fi
                    # else
                    # echo "could not locate fna/fasta files"
                fi 
                echo "--------------------------------------------------------------------------------"

        ###############################################################################
        ## step-03a: If the data is not located then, break 
            if [ -z "$fasta_file_path" ] && [ -z "$fastq_file_path" ] && [ -z "$pod5_file_path" ]; then 
                echo "--------------------------------------------------------------------------------"
                echo "NO FILES FOUND!"
                echo "  In current directory (or sub-directory) .fasta .fna .fastq.gz or pod5 files could not not be located "
                echo "  Or, the files have different suffix (currently recognisable suffix are .fasta .fna id_R1_001.fastq.gz) "
                echo "  Please create a directory and place your files, and re-run"
                echo "  "
                echo "  for e.g."
                echo "  "
                echo "      for fasta files"
                echo "      data/my_fasta/1.fasta"
                echo "      data/my_fasta/2.fasta"
                echo "      data/my_fasta/3.fasta"
                echo "      data/my_fasta/...."
                echo "      "
                echo "      for fastq.gz files"
                echo "      data/my_fastq/a_R1_001.fastq.gz"
                echo "      data/my_fastq/a_R2_001.fastq.gz"
                echo "      data/my_fastq/b_R1_001.fastq.gz"
                echo "      data/my_fastq/..."
                echo "--------------------------------------------------------------------------------"
                exit
            fi 
        ###############################################################################
        ## step-04: create a list and summary file

            ## step-04b: summary file
            ( rm result_summary.read_me.txt ) > /dev/null 2>&1

            if [ ! -z $fasta_file_path ]; then

                fasta_file_count=$(ls $fasta_file_path | wc -l )
                test_fasta_file=$(ls $fasta_file_path | head -1 )
                fasta_file_length=$(cat "$fasta_file_path/$test_fasta_file" | wc -c )
                if [[ $fasta_file_length -gt 500000 ]]; then
                    type_of_files=bacterial_fasta
                    else
                    type_of_files=prophage_fasta
                fi
                echo "$fasta_file_count $type_of_files files found at $fasta_file_path"
                echo "Note that, genomes <500,000 bp are consider are of phage!"
                echo "--------------------------------------------------------------------------------"
                echo "$fasta_file_count $type_of_files files found at $fasta_file_path" > result_summary.read_me.txt
            fi

            if [ ! -z $fastq_file_path ]; then
                fastq_file_count=$(ls $fastq_file_path/*.fastq.gz | wc -l )
                echo "$fastq_file_count fastq.gz (raw_read) files found at $fastq_file_path"
                echo "$fastq_file_count fastq.gz (raw_read) files found at $fastq_file_path" >> result_summary.read_me.txt
            fi

            if [ ! -z $pod5_file_path ]; then
                pod5_file_count=$(ls $pod5_file_path | wc -l )
                echo "$pod5_file_count pod5 files found at $pod5_file_path"
                echo "$pod5_file_count pod5 files found at $pod5_file_path" >> result_summary.read_me.txt
            fi


            ## list file 
            if [ "$type_of_files" == bacterial_fasta ] ; then
                #echo "$fasta fasta found, writing list.my_bacterial_fasta.txt file"
                (ls $fasta_file_path | awk -F'/' '{print $NF}'| sed 's/\.fasta//g' | sort -u > list.bacterial_fasta.txt ) > /dev/null 2>&1
            fi

            if [ "$type_of_files" == prophage_fasta ] ; then
                #echo "$fasta fasta found, writing list.my_prophage_fasta.txt file"
                (ls $fasta_file_path | awk -F'/' '{print $NF}'| sed 's/\.fasta//g' | sort -u > list.prophage_fasta.txt ) > /dev/null 2>&1
            fi

            if [ ! -z "$fastq_file_count"  ] ; then
                if [ "$fastq_file_count" -ne 0 ] ; then
                    echo "$fastq_file_count fastq/fastq.gz found, writing list.my_fastq.txt file"
                    (ls $fastq_file_path/*.fastq.gz | awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' | awk -F'_' '{print $1}' | sort -u > list.fastq.txt ) > /dev/null 2>&1
                fi
            fi

            echo "--------------------------------------------------------------------------------"
        ###############################################################################
        else
        echo "--------------------------------------------------------------------------------"
        echo "\"data\" folder not found"
        echo "all you data should be placed under the folder \"data\""
        echo "for e.g.,"
        echo "data/my_fastqs/ABC_R1.fastq"
        echo "data/my_fastqs/ABC_R2.fastq"
        echo "data/my_fastqs/....."
        echo "--------------------------------------------------------------------------------"
        exit
    fi
 
###############################################################################
## step-05: combined-pipelines or single-step-pipelines
    echo "combined-pipelines or single-step-pipelines?"
    echo "  for combined-pipelines type C and press enter"
    echo "  for single-step-pipelines type S and press enter"
    read pipeline_type
    if [ "$pipeline_type" = "C" ] ; then 
        echo "okay, showing combined-pipelines"
        echo "--------------------------------------------------------------------------------"
        ## step-05-01: get combined-pipelines
            ls /home/groups/VEO/scripts_for_users/cp*.sh | awk -F'/' '{print $NF}' 
            echo "--------------------------------------------------------------------------------"
            echo ""
            echo "which pipeline you would like to run (provide only the number)?"
            echo "for e.g. to run fastANI type 0041 or cp0010 (and press enter)"
            read pipeline_number
            pipeline=$(ls /home/groups/VEO/scripts_for_users/"$pipeline_number"*)
            pipeline_name=$(basename "$pipeline" .sh)
            pipeline_id=$(ls /home/groups/VEO/scripts_for_users/"$pipeline_number"* | awk -F'/'  '{print $NF}' | sed 's/\.sh//g' )
            echo "--------------------------------------------------------------------------------"
            echo "submitting $pipeline_id"
        elif [ "$pipeline_type" = "S" ] ; then
        echo "okay, showing single-step-pipelines"
        ## step-05-02: get pipeline
            ls /home/groups/VEO/scripts_for_users/*.sh | awk -F'/' '{print $NF}' | grep -v "download" | grep -v ^x | grep -v ^s
            echo "--------------------------------------------------------------------------------"
            echo "  which pipeline you would like to run (provide only the number)?"
            echo "  for e.g. to run fastANI type 0041 (and press enter)"
            read pipeline_number
            pipeline=$(ls /home/groups/VEO/scripts_for_users/"$pipeline_number"*)
            pipeline_name=$(basename "$pipeline" .sh)
            pipeline_id=$(ls /home/groups/VEO/scripts_for_users/"$pipeline_number"* | awk -F'/'  '{print $NF}' | sed 's/\.sh//g' )
            send_email=yes
            echo "--------------------------------------------------------------------------------"
            echo "submitting $pipeline_id"
        ###############################################################################
        ## step-05-02-01: depending on pipeline input may differ so

        if [ "$pipeline_number" = "0064" ] ; then 
            if [ ! -f list.my_fasta.txt ] || [ ! -f list.prophage_fasta.txt ] ; then 
                if [ -d results ] ; then
                    if [ ! -z "$(ls results/ | grep 'assembly')" ]; then
                        echo "--------------------------------------------------------------------------------"
                        ls results/ | grep 'assembly'
                        echo "--------------------------------------------------------------------------------"
                        echo "assembly folder found, which should be processed?"
                        echo "provide only the number" 
                        echo "for e.g. for 0052_metagenome_assembly_by_fly, type 0052 (and press enter)" 
                        read assembly_pipeline_number
                        number_of_fasta=$(ls results/$assembly_pipeline_number*/all_fasta/ | wc -l )
                        if [ "$number_of_fasta" -ne 0 ]; then
                            fasta_file_path=$(ls results/ | grep $assembly_pipeline_number )
                            ls results/$assembly_pipeline_number*/all_fasta/ | sed 's/\.fasta//g' > list.my_fasta.txt
                            echo "okay, $number_of_fasta fasta found and writing list.my_fasta.txt "
                            echo "$number_of_fasta fasta files found at $fasta_file_path" >> result_summary.read_me.txt
                            else
                            echo "no fasta found in results/$assembly_pipeline_number*/all_fasta/"
                            break
                        fi 
                    fi
                    else
                    echo "ERROR: fasta files not found in data or results folder"
                    break
                fi 
            fi
        fi
    fi
        ###############################################################################
        ## step-05-02-02: parameter/yaml file
            ( mkdir -p tmp/parameters ) > /dev/null 2>&1
            (cp /home/groups/VEO/scripts_for_users/supplementary_scripts/parameter_files/"$pipeline_number"_*.parameters.yaml tmp/parameters) > /dev/null 2>&1
            echo "--------------------------------------------------------------------------------"
            echo "  working parameters are now stored at tmp/*.yaml file"
            echo "  if you wish, you can change the paramteres"
            echo "  else just press enter to continue"
            echo "  NOTE: for some scripts, parameter file is not required"
            echo "  or script is not updated to change the paramters (work in progress), just press enter"
            echo "--------------------------------------------------------------------------------"
            read
            echo "Continuing with the script."
        ###############################################################################
        ## step-05-02-03: create a sbatch file

            ( mkdir -p tmp/sbatch ) > /dev/null 2>&1
            ( mkdir -p tmp/slurm ) > /dev/null 2>&1
            ( rm tmp/slurm/*.* ) > /dev/null 2>&1

            echo $pipeline > tmp/tmp.txt
            cat /home/groups/VEO/scripts_for_users/supplementary_scripts/0000_veo_pipeline_template.sbatch \
            tmp/tmp.txt \
            > tmp/sbatch/$pipeline_name.$start_time.sbatch
            sed -i "s/your_email@example.com/$user_email/g" tmp/sbatch/$pipeline_name.$start_time.sbatch
            sed -i "s/0000_veo_pipeline/'$pipeline_name'/g" tmp/sbatch/$pipeline_name.$start_time.sbatch
            sed -i "s/send_email_answer/yes/g" tmp/sbatch/$pipeline_name.$start_time.sbatch

            # assembly=$(echo $pipeline_id | grep assembly )
            # if [ ! -z $assembly ] ; then 
            #     sed -i "s/--partition=long/--partition=long/g" tmp/sbatch/$pipeline_name.$start_time.sbatch
            # fi

            # gpu=$(echo $pipeline_id | grep _on_gpu )
            # if [ ! -z $gpu ] ; then 
            #     sed -i "s/--partition=long/--partition=gpu-test/g" tmp/sbatch/$pipeline_name.$start_time.sbatch
            #     sed -i '7i#SBATCH --gres=gpu:1' tmp/sbatch/$pipeline_name.$start_time.sbatch
            # fi

        ###############################################################################
        ## step-05-02-04: run sbatch file

            # Submit the sbatch command and capture the job ID
            job_id=$(sbatch tmp/sbatch/$pipeline_name.$start_time.sbatch | awk '{print $NF}')

            # Check the status of the submitted job
            job_status=$(squeue -j $job_id -h -o "%T")
            node=$(squeue -j $job_id -h | awk '{print $1}'  | sort -u | sed 's/\\n/_/g; s/\\n$//' )

            echo "--------------------------------------------------------------------------------" 
            echo "Hey $user_name ( $user_id, $user_email ) " 
            echo "the script $pipeline_id is submitted with the job_id $job_id "
            echo "you are done for now!"
            echo "you will receive an email once the run is complete"
            echo "details (logs) of the running script will be at: "
            echo "      tmp/slurm/$job_id.err.0000_veo_pipeline.txt"
            echo "      tmp/slurm/$job_id.out.0000_veo_pipeline.txt"
            echo "the ouput of the pipeline will be in the "results" directory"
            echo "you can close the terminal by pressing control + c or you can keep observering the status"
            echo "updating the status in 1 min"
            echo "--------------------------------------------------------------------------------"

            # Loop until the job completes
            while [ ! -z "$job_status" ]; do
                sleep 60 # Sleep for 1 minute
                echo "$pipeline_id with the $job_id status is $job_status on $node"
                echo "updating the status in 1 min"
                job_status=$(squeue -j $job_id -h -o "%T")
                echo "--------------------------------------------------------------------------------"
            done
            
            echo "the script $pipeline_id is sucessfully submitted"
            echo "the current status is " 
            echo "--------------------------------------------------------------------------------"
            squeue -u $user_id
            echo "--------------------------------------------------------------------------------"
            echo "you can check the status by <squeue -u $user_id>" 
            echo "Once the status is empty, the ouput of the pipeline should be in the results directory"
            echo "Cheers, exiting !!!"


###############################################################################
## footer
    end_time=$(date +"%Y%m%d_%H%M%S")
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/time_calculations.sh "$start_time" "$end_time"
###############################################################################
