#!/bin/bash
#SBATCH --job-name=0992_calculate_abundance_from_degenerative_primer
#SBATCH --partition=standard,long,gpu-veo,gpu,gpu-test,interactive
#SBATCH --output=results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.out
#SBATCH --error=results/0992_calculate_abundance_from_degenerative_primer/tmp/slurm/%j.err
#SBATCH --mem=49G
#SBATCH --cpus-per-task=10
############################################################################### 
## header and preparation
	pipeline=0992_calculate_abundance_from_degenerative_primer
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    rawFastqFile=$(grep my_fastq_file $parameters | awk '{print $2}')
    subsampling=$(grep my_subsample_choise $parameters | awk '{print $2}')
    database=$(grep my_database $parameters  | awk '{print $2}')
    anticipated_read_length=$(grep my_anticipated_read_length $parameters | awk '{print $2}')
    tool=$(grep my_tool $parameters | awk '{print $2}')
    QC=10
    threads=$SLURM_CPUS_PER_TASK
    minlength=$(( $anticipated_read_length - 50 ))
    maxlength=$(( $anticipated_read_length + 200 ))
    mismatches=( 0 ) # 0  1 2 3 4 
    subsamples_list=( 1000000 2000000 3000000 4000000 )
	bp=$wd/tmp/list_BarcodePrimers

    echo "---------------------------------------------------------------------"
    log "QC : $QC"
    log "threads : $threads"
    log "anticipated_read_length : $anticipated_read_length"
    log "minlength : $minlength"
    log "maxlength : $maxlength"
    log "rawFastqFile : $rawFastqFile"
    log "subsampling : $subsampling"
    log "database : $database"
    for mismatch in "${mismatches[@]}" ; do 
        log "mismatch : $mismatch"
    done
    echo "---------------------------------------------------------------------"

############################################################################### 
## step-01: create barcode files 
	if [ ! -f $bp/list.barcodes_all.RC.uniq.txt ] ; then 
        log "STARTED : step-01: create barcode files"

        awk 'NR>1 {print $2}' tmp/parameters/$pipeline.my_barcode.txt \
        > $wd/tmp/lists/samples.txt

        tail -n +2 tmp/parameters/$pipeline.my_barcode.txt | while read -r line; do
            id=$(echo $line | awk '{print $2}' )
			if [ ! -f $bp/samples/$id/list.barcodes_all.RC.with_id.txt ] ; then 
				log "creating barcode files: $id "
				(mkdir -p $bp/samples/$id ) > /dev/null 2>&1

				F_primer=$(echo $line | awk '{print $4}' )
				R_primer=$(echo $line | awk '{print $5}' )
				echo ">$id"_F >> $bp/samples/$id/list.barcodes_F.fasta
				echo "$F_primer" >> $bp/samples/$id/list.barcodes_F.fasta
				echo ">$id"_R >> $bp/samples/$id/list.barcodes_R.fasta
				echo "$R_primer" >> $bp/samples/$id/list.barcodes_R.fasta

				python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_regenerated_primer.py \
				-i $bp/samples/$id/list.barcodes_F.fasta -o $bp/samples/$id/list.barcodes_F.fasta

				python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_regenerated_primer.py \
				-i $bp/samples/$id/list.barcodes_R.fasta -o $bp/samples/$id/list.barcodes_R.fasta

				python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/reverse_complement.py \
				-i $bp/samples/$id/list.barcodes_F.fasta -o $bp/samples/$id/list.barcodes_F_RC.fasta 

				python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/reverse_complement.py \
				-i $bp/samples/$id/list.barcodes_R.fasta -o $bp/samples/$id/list.barcodes_R_RC.fasta

				cat $bp/samples/$id/list.barcodes_F.fasta | grep -v ">" > $bp/samples/$id/list.barcodes_F.txt
				cat $bp/samples/$id/list.barcodes_R.fasta | grep -v ">" > $bp/samples/$id/list.barcodes_R.txt
				cat $bp/samples/$id/list.barcodes_F_RC.fasta | grep -v ">" > $bp/samples/$id/list.barcodes_F_RC.txt
				cat $bp/samples/$id/list.barcodes_R_RC.fasta | grep -v ">" > $bp/samples/$id/list.barcodes_R_RC.txt
                cat $bp/samples/$id/list.barcodes_F.fasta $bp/samples/$id/list.barcodes_R.fasta >> $bp/samples/$id/list.barcodes_FR.fasta 
                cat $bp/samples/$id/list.barcodes_F_RC.fasta $bp/samples/$id/list.barcodes_R_RC.fasta >> $bp/samples/$id/list.barcodes_RC.fasta 

				# ## arrange F and R_RC 
					for barcodes_R_RC in $(cat $bp/samples/$id/list.barcodes_R_RC.fasta | grep -v ">" ); do
						for barcodes_F in $(cat $bp/samples/$id/list.barcodes_F.fasta | grep -v ">" ); do
							echo "$barcodes_F $barcodes_R_RC" >> $bp/samples/$id/list.barcodes.F_R_RC.txt
						done
					done

				# ## arrange R and F_RC 
					for barcodes_R in $(cat $bp/samples/$id/list.barcodes_R.fasta | grep -v ">" ); do
						for barcodes_F_RC in $(cat $bp/samples/$id/list.barcodes_F_RC.fasta | grep -v ">" ); do
							echo "$barcodes_R $barcodes_F_RC" >> $bp/samples/$id/list.barcodes.R_F_RC.txt
						done
					done

				awk '{print $1}' $bp/samples/$id/list.barcodes.F_R_RC.txt  > $bp/samples/$id/list.barcodes.F.reseperated.txt
				awk '{print $2}' $bp/samples/$id/list.barcodes.F_R_RC.txt > $bp/samples/$id/list.barcodes.R_RC.reseperated.txt
				awk '{print $1}' $bp/samples/$id/list.barcodes.R_F_RC.txt > $bp/samples/$id/list.barcodes.R.reseperated.txt
				awk '{print $2}' $bp/samples/$id/list.barcodes.R_F_RC.txt > $bp/samples/$id/list.barcodes.F_RC.reseperated.txt

				cat $bp/samples/$id/list.barcodes.F.reseperated.txt $bp/samples/$id/list.barcodes.R.reseperated.txt > $bp/samples/$id/list.barcodes_all.FR.txt 
				cat $bp/samples/$id/list.barcodes.R_RC.reseperated.txt $bp/samples/$id/list.barcodes.F_RC.reseperated.txt > $bp/samples/$id/list.barcodes_all.RC.txt

				cat $bp/samples/$id/list.barcodes.F.reseperated.txt $bp/samples/$id/list.barcodes.R.reseperated.txt | sed "s/^/$id\t/" > $bp/samples/$id/list.barcodes_all.FR.with_id.txt 
				cat $bp/samples/$id/list.barcodes.R_RC.reseperated.txt $bp/samples/$id/list.barcodes.F_RC.reseperated.txt | sed "s/^/$id\t/" > $bp/samples/$id/list.barcodes_all.RC.with_id.txt

				cat $bp/samples/$id/list.barcodes_all.FR.txt >> $bp/list.barcodes_all.FR.txt 
				cat $bp/samples/$id/list.barcodes_all.RC.txt >> $bp/list.barcodes_all.RC.txt

				cat $bp/samples/$id/list.barcodes_all.FR.with_id.txt >> $bp/list.barcodes_all.FR.with_id.txt 
				cat $bp/samples/$id/list.barcodes_all.RC.with_id.txt >> $bp/list.barcodes_all.RC.with_id.txt

                cat $bp/samples/$id/list.barcodes_F.fasta $bp/samples/$id/list.barcodes_R.fasta >> $bp/list.barcodes_FR.fasta 
                cat $bp/samples/$id/list.barcodes_F_RC.fasta $bp/samples/$id/list.barcodes_R_RC.fasta >> $bp/list.barcodes_RC.fasta 

				else
				log "ALREADY FINISHED : creating barcode files : $id "

			fi
        done

		cat $bp/list.barcodes_all.FR.txt | sort | uniq > $bp/list.barcodes_all.FR.uniq.txt
		cat $bp/list.barcodes_all.RC.txt | sort | uniq > $bp/list.barcodes_all.RC.uniq.txt
        # paste $bp/list.barcodes_FR.with_id.fasta $bp/list.barcodes_RC.with_id.fasta > $bp/list.barcodes_FR_RC.fasta 
        # paste $bp/list.barcodes_all.FR.with_id.txt $bp/list.barcodes_all.RC.with_id.txt | awk '{print $1, $2, $4}'  > results/0992_calculate_abundance_from_degenerative_primer/tmp/list_BarcodePrimers/list.barcodes_all.FR_RC.with_id.txt

		else
		log "ALREADY FINISHED : step-01: create barcode files"
	fi

###############################################################################
## step-02: Count total number of reads, QC,

            ## if fastqs need to combine
                # if [ ! -f $rawFastqFile ] ; then 
                #     for i in $(ls results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_files/pass/ ); do
                #         echo "$i"
                #         cat results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/02_fast5_to_basecall/all_files/pass/*.fastq \
                #         >> $rawFastqFile
                #     done
                #     else
                #     log "ALREADY FINISHED : combining all fastqs"
                # fi 
    
    if [ ! -f $wd/tmp/total_number_of_reads.txt ]; then 
        log "counting total number of reads"
        count_reads_from_fastq $rawFastqFile > $wd/tmp/total_number_of_reads.txt
    fi
    raw_reads=$(cat $wd/tmp/total_number_of_reads.txt)
    echo "raw_reads : $raw_reads" 

    ## QC check for raw reads
    if [ ! -f $raw_files/raw_read_distribution.tsv ] ; then 
        log "getting raw read length distribution"
        python3 $suppl_scripts/utilities/fastq_read_distribution.py -i $rawFastqFile -o $raw_files/raw_read_distribution.tsv
        else 
        log "ALREADY FINISHED : getting raw read length distribution"
    fi

    if [ ! -f $raw_files/raw_read_distribution.png ]; then 
        log "STARTED: plotting raw read length distribution"
        source /home/groups/VEO/tools/biopython/myenv/bin/activate 
        python $suppl_scripts/plots/histogram.double_column_input.py \
        -i $raw_files/raw_read_distribution.tsv \
        -r 100
        deactivate
        log "FINISHED : plotting raw read length distribution"
        else
        log "ALREADY FINISHED : plotting raw read length distribution"
    fi
    ## First check-point for QC for $rawFastqFile
    # exit

############################################################################### 
## step-03: filter reads (by chopper) for $QC

    if [ ! -f $raw_files/all_combined.$QC.fastq ] ; then 
        log "STARTED : filtering reads (by chopper) for QC $QC"
        source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 
        zcat $rawFastqFile | chopper -t $threads --minlength $minlength --maxlength $maxlength -q $QC > $raw_files/all_combined.$QC.fastq
        log "FINISHED : filtering reads (by chopper) for QC $QC"
        else
        log "ALREADY FINISHED : filtering reads (by chopper) for QC $QC"
    fi
    filteredFastqFile=$raw_files/all_combined.$QC.fastq

    if [ ! -f $wd/tmp/total_number_of_filtered_reads.$QC.txt ] ; then 
        log "counting total number of filtered reads"
        count_reads_from_fastq $filteredFastqFile > $wd/tmp/total_number_of_filtered_reads.$QC.txt
    fi

    filtered_reads=$(cat $wd/tmp/total_number_of_filtered_reads.$QC.txt)
    log "filtered_reads : $filtered_reads" 

###############################################################################
## step-04: subsampling
    
    if [ ! -d $wd/subsampled ] ; then 
        (mkdir -p $wd/subsampled ) > /dev/null 2>&1

        if [ "$subsampling" == "No" ] ; then 
            subsample=$filtered_reads
            cp $filteredFastqFile $wd/subsampled/all_combined.subsampled_"$subsample".fastq

            ## converting (original unsampled) fastq to fasta
            log "STARTED: converting (original unsampled) fastq to fasta"

            /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk seq \
            -a $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
            > $wd/subsampled/all_combined.subsampled_"$subsample".fastq.fasta

            log "FINISHED : converting (original unsampled) fastq to fasta"

            elif [ "$subsampling" == "Yes" ] ; then
                subsamples=${subsamples_list[@]}

                source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 

                for subsample in "${subsamples[@]}"; do
                    if [ ! -f $wd/subsampled/all_combined.subsampled_"$subsample".fastq ] ; then 
                        log "subsampling for $subsample"
                        rasusa -i $filteredFastqFile \
                        -n $subsample -o $wd/subsampled/all_combined.subsampled_"$subsample".fastq -O u

                        /home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk seq \
                        -a $wd/subsampled/all_combined.subsampled_"$subsample".fastq \
                        > $wd/subsampled/all_combined.subsampled_"$subsample".fastq.fasta
                        else
                        log "ALREADY FINISHED : subsampling for $subsample"
                    fi
                done

            else
            echo "provide subsamples option"
        fi 

        else
        log "ALREADY FINISHED : subsampling"
    fi

    ## needed for below script
    if [ "$subsampling" == "No" ] ; then 
        subsamples=$filtered_reads
        elif [ "$subsampling" == "Yes" ] ; then
        subsamples=${subsamples_list[@]}
        else
        echo "provide subsamples option"
    fi 
###############################################################################
## step-05: extract_read_ids_from_fastq_if_pattern_present
    # file written is $wd/lists/list.$barcode.read_ids.$subsample.txt
    # file written is $wd/lists/list.$barcode.read_ids.only.$subsample.txt

                ## Notes: tried to run vserach but it was not working. Gave only 1 hit!!!
                    # /home/groups/VEO/tools/vsearch/vsearch-2.28.1/bin/vsearch \
                    # --usearch_global test.fasta \
                    # --db $wd/subsampled/all_combined.subsampled_6377275.fastq.fasta \
                    # --id 0.94 \
                    # --strand both \
                    # --maxaccepts 0 \
                    # --maxrejects 0 \
                    # --userout results.txt \
                    # --userfields query+target

    ## BLAST Capture the read ids from the fastq file, if pattern present
        ## With BLAST its possible to use multiple mismatches (from BLAST output).
        ## process FR and RC seperately
        ## output will be $raw_files/read_ids_extracted/$barcode_FR.tsv
        ## output will be $raw_files/read_ids_extracted/$barcode_RC.tsv 
        if [ ! -d $raw_files/read_ids_extracted ] ; then 
            mkdir $raw_files/read_ids_extracted
            mkdir -p $wd/tmp/barcode_tmp

            for subsample in "${subsamples[@]}"; do

                if [ ! -f $wd/subsampled/all_combined.subsampled_"$subsample".fastq.fasta.db ] ; then 
                    /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
                    -in $wd/subsampled/all_combined.subsampled_"$subsample".fastq.fasta \
                    -dbtype nucl -out $wd/subsampled/all_combined.subsampled_"$subsample".fastq.fasta.db
                fi

                for barcode_FR in $(cat $bp/list.barcodes_all.FR.uniq.txt); do 
                    log "creating and submitting sbatch for $barcode_FR"
                    echo $barcode_FR > $wd/tmp/barcode_tmp/$barcode_FR.fasta
                    sed "s/ABC/$barcode_FR/g" $suppl_scripts/$pipeline.get_reads_by_blastn.sbatch | sed "s/XYZ/$subsample/g" \
                    > $wd/tmp/sbatch/extract_read_ids.$barcode_FR.$subsample.sbatch
                    sbatch $wd/tmp/sbatch/extract_read_ids.$barcode_FR.$subsample.sbatch

                    wait_for_jobs_to_complete 100
                done 

                for barcode_RC in $(cat $bp/list.barcodes_all.RC.uniq.txt); do 
                    log "creating and submitting sbatch for $barcode_FR"
                    echo $barcode_RC > $wd/tmp/barcode_tmp/$barcode_RC.fasta
                    sed "s/ABC/$barcode_RC/g" $suppl_scripts/$pipeline.get_reads_by_blastn.sbatch | sed "s/XYZ/$subsample/g" \
                    > $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch
                    sbatch $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch

                    wait_for_jobs_to_complete 100
                done 

            done
            else
            log "ALREADY FINISHED : extract_read_ids_from_fastq_if_pattern_present"
        fi
        ## First check point
        wait_till_all_job_finished_with_name extr

        ## How many reads were extracted after above BLAST loop? 
            if [ ! -f $bp/list.read_ids_FR.uniq.blast.txt ] ; then 
                for barcode_FR in $(cat $bp/list.barcodes_all.FR.uniq.txt ); do 
                    awk '{print $2}' $raw_files/read_ids_extracted/$barcode_FR.tsv >> $bp/list.read_ids_FR.txt 
                done
                    sort $bp/list.read_ids_FR.txt | uniq > $bp/list.read_ids_FR.uniq.blast.txt
            fi

            if [ ! -f $bp/list.read_ids_RC.uniq.blast.txt ] ; then 
                for barcode_RC in $(cat $bp/list.barcodes_all.RC.uniq.txt ); do 
                    awk '{print $2}' $raw_files/read_ids_extracted/$barcode_RC.tsv >> $bp/list.read_ids_RC.txt 
                done
                    sort $bp/list.read_ids_RC.txt | uniq > $bp/list.read_ids_RC.uniq.blast.txt
            fi 

                        ## DEPRECATED: Directly capture the read ids from the fastq file, if pattern present
                            ## process FR and RC seperately by direct capturing the seqeuence 
                                # for subsample in "${subsamples[@]}"; do
                                #     # echo "extract_read-ids_from_fastq_if_pattern_present for $subsample"

                                #     for barcode in $(cat $bp/list.barcodes_all.FR.uniq.txt); do 
                                #         if [ ! -f $wd/tmp/lists/list.$barcode.read_ids.only.$subsample.txt ] ; then 
                                #             log "creating and submitting sbatch for barcode $barcode"
                                #             sed "s/ABC/$barcode/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_extract_read_ids.sbatch | sed "s/XYZ/$subsample/g" \
                                #             > $wd/tmp/sbatch/extract_read_ids.$barcode.$subsample.sbatch
                                #             sbatch $wd/tmp/sbatch/extract_read_ids.$barcode.$subsample.sbatch
                                # 			# else
                                # 			# log "ALREADY FINISHED : $barcode : creating and submitting sbatch for barcode $barcode"
                                #         fi
                                #     done
                                    
                                #     for barcode_RC in $(cat $bp/list.barcodes_all.RC.uniq.txt); do 
                                #         if [ ! -f $wd/tmp/lists/list.$barcode.read_ids.only.$subsample.txt ] ; then 
                                #             log "creating and submitting sbatch for barcode_RC $barcode_RC"
                                #             sed "s/ABC/$barcode_RC/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_extract_read_ids.sbatch | sed "s/XYZ/$subsample/g" \
                                #             > $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch
                                #             sbatch $wd/tmp/sbatch/extract_read_ids.$barcode_RC.$subsample.sbatch
                                # 			# else
                                # 			# log "ALREADY FINISHED : $barcode_RC : creating and submitting sbatch for barcode_RC $barcode_RC"
                                #         fi
                                #     done

                                # done 

                            ## process FR and RC both together (find two pattern on single reads)
                                    # for subsample in "${subsamples[@]}"; do
                                    #     while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do
                                    #         if [ ! -f $wd/tmp/lists/list.$barcode.$barcode_RC.read_ids.$subsample.txt ] ; then 

                                    #             echo "extractign reads ids if both $barcode $barcode_RC present"

                                    #             sed "s/ABCDEF/$barcode/g" $suppl_scripts/0992_extract_read_ids_if_two_patterns_present.sbatch \
                                    #             | sed "s/GHIJKL/$barcode_RC/g" \
                                    #             | sed "s/XYZ/$subsample/g" \
                                    #             > $wd/tmp/sbatch/0992_extract_read_ids_if_two_patterns_present.$barcode.$barcode_RC.$subsample.sbatch

                                    #             # Check the number of running jobs and wait if there are more than 300
                                    #             while [ $(count_running_jobs) -gt 300 ]; do
                                    #                 echo "More than 300 jobs running. Waiting..."
                                    #                 sleep 10 # Wait for 10 seconds before checking again
                                    #             done

                                    #             sbatch $wd/tmp/sbatch/0992_extract_read_ids_if_two_patterns_present.$barcode.$barcode_RC.$subsample.sbatch
                                    #         fi
                                    #     done < $bp/"list.barcodes_all.FR.txt" 3< $bp/"list.barcodes_all.RC.txt"
                                    #     # done < <(head -n 5 "$bp/list.barcodes_all.FR.txt") 3< <(head -n 5 "$bp/list.barcodes_all.RC.txt") ## for testing
                                    # done

                            ## second (b) checkpoint for sbatch 
                            # exit 
###############################################################################
## step-06: combine read ids from F, R and RC sequences, remove duplicates, also make a count
    # ( rm $wd/tmp/slurm/*.* ) > /dev/null 2>&1

    ## mismatch allowed 
        if [ ! -f $wd/tmp/mismtach_allowed_finished.txt ] ; then 
            for subsample in "${subsamples[@]}"; do
                for mismatch in "${mismatches[@]}" ; do 
                    log "for $subsample reads and $mismatch mismatches, combining read ids, removing duplicates and counting "
                    while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do

                        if [ ! -f $raw_files/read_ids_extracted/$barcode_FR.tsv.tmp ] ; then
                            awk -v mismatch="$mismatch" '$8 == mismatch && $9 == 0 && $10 == 100 {print $2}' \
                            $raw_files/read_ids_extracted/$barcode_FR.tsv \
                            > $raw_files/read_ids_extracted/$barcode_FR.$mismatch.tsv.tmp

                            wait_for_file_existence_and_completion $raw_files/read_ids_extracted/$barcode_FR.$mismatch.tsv.tmp
                        fi

                        if [ ! -f $raw_files/read_ids_extracted/$barcode_RC.tsv.tmp ] ; then 
                            awk -v mismatch="$mismatch" '$8 == mismatch && $9 == 0 && $10 == 100 {print $2}' \
                            $raw_files/read_ids_extracted/$barcode_RC.tsv \
                            > $raw_files/read_ids_extracted/$barcode_RC.$mismatch.tsv.tmp

                            wait_for_file_existence_and_completion $raw_files/read_ids_extracted/$barcode_RC.$mismatch.tsv.tmp
                        fi

                    done < "$bp/list.barcodes_all.FR.uniq.txt" 3< "$bp/list.barcodes_all.RC.uniq.txt" 
                    # done < <(head -n 5 "$bp/list.barcodes_all.FR.txt") 3< <(head -n 5 "$bp/list.barcodes_all.RC.txt") ## for testing
                done 
            done
            log "mismtach allowed finished" > $wd/tmp/mismtach_allowed_finished.txt
            else
            log "ALREADY FINISHED : combining read ids, removing duplicates and counting "
        fi
 
        ## need to finish above step, so that all files are ready for below step
        ## Now, need to get read ids that carries FR and RC (F and r_RC and R and F_RC) both on a single read
        ## output will be $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids_present_in_both_FR_RC.$mismatch.$subsample.txt
        ## output will be $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids_present_in_either_FR_RC.$mismatch.$subsample.txt
        ## output will be $wd/tmp/read_ids.$mismatch.$subsample.tsv

        for subsample in "${subsamples[@]}"; do
            for mismatch in "${mismatches[@]}" ; do 
                if [ ! -f $wd/tmp/read_ids.$mismatch.$subsample.tsv ] ; then 
                
                    log "for $subsample combining read ids, removing duplicates and counting "

                    echo "barcode_FR barcode_RC mismatch num_of_barcode_FR num_of_barcode_RC duplicate_read_ids non_duplicate_final_read_ids" \
                    > $wd/tmp/read_ids.$mismatch.$subsample.tsv

                    while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do

                        sed "s/ABC/$barcode_FR/g" $suppl_scripts/$pipeline.combine_read_id.sbatch \
                        | sed "s/JKL/$barcode_RC/g" | sed "s/XYZ/$subsample/g" | sed "s/DEFGHI/$mismatch/g" \
                        > $wd/tmp/sbatch/$pipeline.combine_read_id.$barcode_FR.$barcode_RC.$subsample.$mismatch.sbatch

                        sbatch $wd/tmp/sbatch/$pipeline.combine_read_id.$barcode_FR.$barcode_RC.$subsample.$mismatch.sbatch
                        wait_for_jobs_to_complete 15 ## dont increase this number, as there will be I/O error writing  $wd/tmp/read_ids.$mismatch.$subsample.tsv file. 

                    done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt" ## here, not using uniq as wish to cover all the samples. 
                    # done < <(head -n 5 "$bp/list.barcodes_all.FR.txt") 3< <(head -n 5 "$bp/list.barcodes_all.RC.txt") ## for testing
                    else
                    log "ALREADY FINISHED: combining read ids, removing duplicates and counting : $subsample "
                fi
            done 
        done
        wait_till_all_job_finished_with_name comb

        ## create $wd/tmp/read_ids.$subsample.tsv (combined mismatch stat)
        for subsample in "${subsamples[@]}"; do
            if [ ! -f $wd/tmp/read_ids.$subsample.tsv ] ; then
                log "RUNNING: creating stat file: $wd/tmp/read_ids.$subsample.tsv"

                awk '{print $1, $2}' $wd/tmp/read_ids.0.$subsample.tsv \
                | sed '1i\FR RC' > $wd/tmp/read_ids.$subsample.tsv
                for mismatch in "${mismatches[@]}" ; do 

                    awk '{print $6}' $wd/tmp/read_ids.$mismatch.$subsample.tsv \
                    | sed "1i\\$mismatch" > $wd/tmp/read_ids.$mismatch.$subsample.tsv.tmp

                    paste $wd/tmp/read_ids.$subsample.tsv \
                    $wd/tmp/read_ids.$mismatch.$subsample.tsv.tmp \
                    > $wd/tmp/read_ids.$subsample.tsv.tmp
                    
                    mv $wd/tmp/read_ids.$subsample.tsv.tmp \
                    $wd/tmp/read_ids.$subsample.tsv 

                    rm $wd/tmp/read_ids.$mismatch.$subsample.tsv.tmp
                done
                else
                log "ALREADY FINISHED: creating stat file: $wd/tmp/read_ids.$subsample.tsv"
            fi
        done

        # OPTIONAL : third (b) checkpoint
        # exit 

                        ## ONLY DURING DEBUGGING for below lines (has to do nothing with above steps)
                            ## Important step to remove below files here, as it will create duplicate count
                            ## Also, its not possible to fix this deletion in after loop
                                # log "RUNNING: removing old files"
                                # for subsample in "${subsamples[@]}"; do
                                #     for sample in $(cat $wd/tmp/lists/samples.txt ); do
                                #         log "removing old files for $subsample $sample"
                                #         rm $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0.$subsample.txt.tmp > /dev/null 2>&1
                                        # rm $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.1.$subsample.txt.tmp > /dev/null 2>&1
                                        # rm $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.2.$subsample.txt.tmp > /dev/null 2>&1
                                        # rm $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.3.$subsample.txt.tmp > /dev/null 2>&1
                                        # rm $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.4.$subsample.txt.tmp > /dev/null 2>&1
                                        # rm $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.5.$subsample.txt.tmp > /dev/null 2>&1
                                #     done 
                                # done
                                # log "FINISHED: removing old files"

        ## combine read ids for all degenerative primers to respective samples
        echo -e "subsample\tsample\tb0\tb1\tb2\tb3\tb4\ta0\ta1\ta2\ta3\ta4" > $wd/stat.tsv 
        for subsample in "${subsamples[@]}"; do
            for sample in $(cat $wd/tmp/lists/samples.txt ); do
                # if [ ! -f $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0.$subsample.txt ] ; then
                    log "RUNNING: combine read ids for all degenerative primers to respective samples : $subsample $sample"

                    ## for each primer generated from degenerative primer, combine read ids for FR and RC
                    if [ ! -f $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.$mismatch.$subsample.txt.tmp ]; then 
                        while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do
                            for mismatch in "${mismatches[@]}" ; do
                                cat $raw_files/read_ids_extracted/list.$barcode_FR.$barcode_RC.read_ids_present_in_both_FR_RC.$mismatch.$subsample.txt \
                                >> $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.$mismatch.$subsample.txt.tmp
                            done
                        done < "$bp/samples/$sample/list.barcodes_all.FR.txt" 3< "$bp/samples/$sample/list.barcodes_all.RC.txt"
                    fi

                    ## VERY VERY IMP: Remove duplicate reas ids. Beacuase of cat command in above loop, there are duplicates read ids (generated from same primer sequence), and need to remove 
                    ## Same read can be identified in to sets for e.g. 0 mismatch and 1 mismatch and 2 mismatch etc.
                    if [ ! -f $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0.$subsample.txt ]; then
                        for mismatch in "${mismatches[@]}" ; do
                            # log "calculating before and after ids for $subsample $sample $mismatch"
                            sort $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.$mismatch.$subsample.txt.tmp \
                            | uniq > $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.$mismatch.$subsample.txt
                        done 
                    fi


                        ## before removing duplicate
                        b0=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0.$subsample.txt.tmp | awk '{print $1}')
                        # b1=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.1.$subsample.txt.tmp | awk '{print $1}')
                        # b2=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.2.$subsample.txt.tmp | awk '{print $1}')
                        # b3=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.3.$subsample.txt.tmp | awk '{print $1}')
                        # b4=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.4.$subsample.txt.tmp | awk '{print $1}')
                        
                        ## after removing duplicate
                        a0=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0.$subsample.txt | awk '{print $1}' )
                        # a1=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.1.$subsample.txt | awk '{print $1}' )
                        # a2=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.2.$subsample.txt | awk '{print $1}' )
                        # a3=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.3.$subsample.txt | awk '{print $1}' )
                        # a4=$( wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.4.$subsample.txt | awk '{print $1}' )
                        echo $subsample $sample $b0 $b1 $b2 $b3 $b4 $a0 $a1 $a2 $a3 $a4 | tee -a $wd/stat.tsv #echo $subsample $sample $b0 $b1 $b2 $b3 $b4 $a0 $a1 $a2 $a3 $a4

                        # cat $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0.$subsample.txt \
                        # $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.1.$subsample.txt \
                        # > $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.01.$subsample.txt
                        # wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.01.$subsample.txt

                        # cat $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.01.$subsample.txt \
                        # $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.2.$subsample.txt \
                        # > $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.012.$subsample.txt
                        # wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.012.$subsample.txt

                        # cat $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.012.$subsample.txt \
                        # $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.3.$subsample.txt \
                        # > $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0123.$subsample.txt
                        # wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0123.$subsample.txt

                        # cat $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.0123.$subsample.txt \
                        # $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.4.$subsample.txt \
                        # > $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.01234.$subsample.txt
                        # wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.01234.$subsample.txt

                        # cat $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.01234.$subsample.txt \
                        # $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.5.$subsample.txt \
                        # > $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.012345.$subsample.txt
                        # wc -l $raw_files/read_ids_extracted/list.$sample.read_ids_present_in_both_FR_RC.012345.$subsample.txt
                # fi
            done 
        done

        # ## OPTINOAL : third (c) checkpoint
        # exit 

                                ## for seperate 
                                    # if [ ! -f $wd/tmp/number_of_reads.read_ids.$subsample.tsv ] ; then 
                                    #     ( mkdir $wd/results/stat ) > /dev/null 2>&1
                                    #     for subsample in "${subsamples[@]}"; do
                                    #         log "for $subsample combining read ids, removing duplicates and counting "
                                    #         while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do
                                    #             num_of_barcode_FR=$(wc -l $wd/tmp/lists/list.$barcode_FR.read_ids.only.$subsample.txt | awk '{print $1}')
                                    #             num_of_barcode_RC=$(wc -l $wd/tmp/lists/list.$barcode_RC.read_ids.only.$subsample.txt | awk '{print $1}')
                                    #             num_of_new_reads_by_RC=$(diff \
                                    #             $wd/tmp/lists/list.$barcode_FR.read_ids.only.$subsample.txt \
                                    #             $wd/tmp/lists/list.$barcode_RC.read_ids.only.$subsample.txt \
                                    #             | grep "^>" | sed 's/^> //' | wc -l )

                                    #             cat $wd/tmp/lists/list.$barcode_FR.read_ids.only.$subsample.txt \
                                    #             $wd/tmp/lists/list.$barcode_RC.read_ids.only.$subsample.txt | \
                                    #             sort | uniq | sed 's/\@//g'> $wd/tmp/lists/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt

                                    #             non_duplicate_read_ids=$(($num_of_barcode_FR + $num_of_new_reads_by_RC ))

                                    #             echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids \
                                    # 			| tee -a $wd/tmp/lists/number_of_reads.$barcode.$barcode_RC.read_ids.$subsample.txt

                                    #             echo $barcode_FR $barcode_RC $num_of_barcode_FR $num_of_barcode_RC $num_of_new_reads_by_RC $non_duplicate_read_ids \
                                    #             >> $wd/tmp/number_of_reads.read_ids.$subsample.tsv
                                    #         done < "$bp/list.barcodes_all.FR.txt" 3< "$bp/list.barcodes_all.RC.txt" ## here, not using uniq as wish to cover all the samples. 

                                    #     done
                                    # fi 

                                ## for combined

                                    # for subsample in "${subsamples[@]}"; do
                                    #     for i in $( awk '{print $1}' $bp/list.barcodes_all.FR.with_id.txt | sort | uniq ) ; do 
                                    #         grep -w "$i" $bp/list.barcodes_all.FR.with_id.txt | awk '{print $2}' > $wd/tmp/lists/list.$i.FR
                                    #         grep -w "$i" $bp/list.barcodes_all.RC.with_id.txt | awk '{print $2}' > $wd/tmp/lists/list.$i.RC

                                    #         total_number_of_reads=0
                                    #         while IFS= read -r barcode_FR && IFS= read -r barcode_RC <&3; do
                                    #             number_of_reads=$(wc -l $wd/tmp/lists/list.$barcode_FR.$barcode_RC.read_ids.$subsample.txt | awk '{print $1}')
                                    #             echo $i $barcode_FR $barcode_RC $number_of_reads \
                                    #             | tee -a $wd/tmp/number_of_reads.read_ids.$subsample.combined.tsv
                                    #             total_number_of_reads=$((total_number_of_reads + number_of_reads))
                                    #         done < "$wd/tmp/lists/list.$i.FR" 3< "$wd/tmp/lists/list.$i.RC"

                                    #         echo $i $filtered_reads | tee -a $wd/tmp/number_of_reads.read_ids.$subsample.combined.count.tsv

                                    #         rm $wd/tmp/lists/list.$i.FR
                                    #         rm $wd/tmp/lists/list.$i.RC
                                    #     done
                                    # done
        
        ## OPTINOAL : third (c) checkpoint
        # exit 
###############################################################################  
## step-07: get seperate fastqs for barcode/match
    ## out file is $raw_files/read_ids_extracted_fastq/$subsample.$sample.0123.fastq
    ## out file is $raw_files/read_ids_extracted_fastq/$subsample.$sample.fastq.stat

    ## note: mismatch loop not necessary, as covered in the sbatch script 
    if [ ! -d $raw_files/read_ids_extracted_fastq ] ; then 
        ( mkdir $raw_files/read_ids_extracted_fastq ) > /dev/null 2>&1 
        for subsample in "${subsamples[@]}"; do
            for sample in $(cat $wd/tmp/lists/samples.txt ); do
                if [ ! -f $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq ] ; then 
                    sed "s/ABC/$subsample/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.get_reads_by_seqtk.sbatch \
                    | sed "s/JKL/$sample/g" | sed "s/XYZ/$mismatch/g" \
                    > $wd/tmp/sbatch/$pipeline.$subsample.$sample.$mismatch.get_reads_by_seqtk.sbatch

                    wait_for_jobs_to_complete 50

                    sbatch $wd/tmp/sbatch/$pipeline.$subsample.$sample.$mismatch.get_reads_by_seqtk.sbatch
                fi 
            done
        done 
    fi
    wait_till_all_job_finished_with_name get

    ## just for QC (run only when above loop is completely finished)
        if [ ! -f $wd/tmp/percentage_reads_got_binned.$QC.txt ] ; then 
            echo -e "subsample\tsample\tmismatch\treads_in_file" > $wd/tmp/my_summary.reads_per_sample.tsv
            number_of_reads=0
            for subsample in "${subsamples[@]}"; do
                for sample in $(cat $wd/tmp/lists/samples.txt ); do
                    for mismatch in "${mismatches[@]}" ; do
                        reads_in_file=$( count_reads_from_fastq $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq )
                        total_number_of_reads=$(( $number_of_reads + $reads_in_file ))
                        number_of_reads=$total_number_of_reads
                        echo -e "$subsample\t$sample\t$mismatch\t$reads_in_file" \
                        | tee -a $wd/tmp/my_summary.reads_per_sample.tsv
                    done
                done
            done 
            percentage_reads_got_binned=$(( $number_of_reads * 100 / $subsample ))
            echo "$percentage_reads_got_binned percentage ($number_of_reads/$subsample) of QC10 reads" | tee -a $wd/tmp/percentage_reads_got_binned.$QC.txt
            else
            cat $wd/tmp/percentage_reads_got_binned.$QC.txt
        fi 

############################################################################### 
## step-08: fastq2fasta for filtered reads 

    for subsample in "${subsamples[@]}"; do
        for sample in $(cat $wd/tmp/lists/samples.txt ); do
            for mismatch in "${mismatches[@]}" ; do
                if [ ! -f $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta ] ; then 
                    echo "fastq2fasta for filtered reads for $subsample $sample $mismatch"

                    python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_fastq2fasta.py \
                    -i $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq \
                    -o $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta 

                    sed -i 's/@//g' $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta 
                    sed -i 's/ .*//g' $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta 

                    reads_in_fasta10=$( count_number_of_sequences_in_fasta $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.fasta  )
                    echo "reads in fasta $reads_in_fasta10"
                fi 
            done
        done
    done
    log "FINISHED : fastq2fasta for filtered reads"
    
###############################################################################
## step-09: filter and trim the barcodePrimer sequence
        for subsample in "${subsamples[@]}"; do
            for sample in $(cat $wd/tmp/lists/samples.txt ); do
                for mismatch in "${mismatches[@]}" ; do

                if [ ! -f $raw_files/read_ids_extracted_fastq/$subsample.$sample.$mismatch.fastq.length_report.txt ] ; then 

                    log "filtering and trimming barcodePrimer sequences for $subsample $sample $mismatch"
                    sed "s/my_subsample/$subsample/g" $suppl_scripts/$pipeline.filtering_and_trimming_barcodePrimer_sequences.sbatch \
                    | sed "s/my_sample/$sample/g" | sed "s/my_mismatch/$mismatch/g" | sed "s/my_qc/$QC/g" \
                    > $wd/tmp/sbatch/$subsample.$sample.$mismatch.filtering_and_trimming_barcodePrimer_sequences.sbatch 

                    sbatch $wd/tmp/sbatch/$subsample.$sample.$mismatch.filtering_and_trimming_barcodePrimer_sequences.sbatch 

                fi 

                done  
            done 
        done 
        wait_till_all_job_finished_with_name filter
###############################################################################
## run blast or Kraken2
    ## for silva database, it take long time to run blast
    ## for custom database, it is faster (as number of sequences are less)

    if [ "$tool" == "blast" ] ; then
        if [ "$database" == "custom" ]; then
            if [ ! -d $raw_files/blast_results ]; then 
                log "STARTED : run blast with custom database"
                ( mkdir -p $raw_files/databases )
                ( mkdir -p $raw_files/blast_results )

                ## reformat multi-line fasta to one line fasta
                awk 'BEGIN {RS=">"; FS="\n"} NR>1 {printf ">%s\n", $1; for (i=2; i<=NF; i++) printf "%s", $i; print ""}' \
                tmp/parameters/$pipeline.query_sequence.fasta \
                > tmp/parameters/$pipeline.query_sequence.2.fasta 

                ## create database for query sequence
                    log "STARTED: find my sequences : create database for query sequence"

                    if [ ! -f $raw_files/databases/query_sequence.fasta.db.ndb ] ; then 
                        /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
                        -in tmp/parameters/$pipeline.query_sequence.2.fasta \
                        -dbtype nucl -out $raw_files/databases/query_sequence.fasta.db
                    fi
                    database=$raw_files/databases/query_sequence.fasta.db 
                    
                    log "FINISHED: find my sequences : create database for query sequence"

                ## run blast for read identification
                log "STARTED: find my sequences : run blast"

                for subsample in "${subsamples[@]}"; do
                    for sample in $(cat $wd/tmp/lists/samples.txt ); do
                        for mismatch in "${mismatches[@]}" ; do

                            if [ ! -f $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv ] ; then 

                                sed "s/my_subsample/$subsample/g" $suppl_scripts/$pipeline.blast_for_read_identification.sbatch \
                                | sed "s/my_sample/$sample/g" | sed "s/my_mismatch/$mismatch/g" | sed "s/my_qc/$QC/g" | sed "s|my_database|${database}|g" \
                                > $wd/tmp/sbatch/blast_for_read_identification.$subsample.$sample.$mismatch.$QC.sbatch

                                sbatch $wd/tmp/sbatch/blast_for_read_identification.$subsample.$sample.$mismatch.$QC.sbatch
                            fi 

                            wait_for_jobs_to_complete 20

                        done
                    done
                done

                log "FINISHED: find my sequences : run blast"
            fi
            wait_till_all_job_finished_with_name blast
        fi 
    fi

    if [ "$tool" == "kraken2" ]; then
        if [ "$database" == "silva" ]; then
            if [ -d $raw_files/blast_results ]; then 
                log "STARTED : run blast with SILVA database"
                ( mkdir -p $raw_files/databases )
                ( mkdir -p $raw_files/blast_results )
                for subsample in "${subsamples[@]}"; do
                    for sample in $(cat $wd/tmp/lists/samples.txt ); do
                        for mismatch in "${mismatches[@]}" ; do

                            if [ ! -f $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv ] ; then 
                                sed "s/my_subsample/$subsample/g" $suppl_scripts/$pipeline.blast_for_read_identification.sbatch \
                                | sed "s/my_sample/$sample/g" | sed "s/my_mismatch/$mismatch/g" | sed "s/my_qc/$QC/g" \
                                > $wd/tmp/sbatch/blast_for_read_identification.$subsample.$sample.$mismatch.$QC.sbatch
                                sbatch $wd/tmp/sbatch/blast_for_read_identification.$subsample.$sample.$mismatch.$QC.sbatch
                            fi 

                            wait_for_jobs_to_complete 20

                        done
                    done
                done
            fi
            wait_till_all_job_finished_with_name blast
        fi

        if [ "$database" == "kraken2" ]; then 
            if [ ! -d $raw_files/kraken2/hits ]; then
                log "STARTED : run kraken2"

                mkdir -p $raw_files/kraken2/hits
                for subsample in "${subsamples[@]}"; do
                    for sample in $(cat $wd/tmp/lists/samples.txt ); do
                        for mismatch in "${mismatches[@]}" ; do

                            if [ ! -f $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.report.out.filled ] ; then 
                                sed "s/my_subsample/$subsample/g" $suppl_scripts/$pipeline.kraken2.sbatch \
                                | sed "s/my_sample/$sample/g" | sed "s/my_mismatch/$mismatch/g" | sed "s/my_qc_value/$QC/g" \
                                > $wd/tmp/sbatch/kraken2.$subsample.$sample.$mismatch.sbatch

                                sbatch $wd/tmp/sbatch/kraken2.$subsample.$sample.$mismatch.sbatch
                            fi 

                            wait_for_jobs_to_complete 20

                        done
                    done
                done
            fi
            wait_till_all_job_finished_with_name 0992_k ## Next time, change this name to kraken2
        fi
    fi

    if [ "$tool" == "emu" ]; then
        log "STARTED : emu with SILVA database"
        if [ ! -d $raw_files/$tool/$database/hits ]; then
            mkdir -p $raw_files/$tool/$database/hits 
            mkdir -p $raw_files/$tool/$database/distribution
            for subsample in "${subsamples[@]}"; do
                for sample in $(cat $wd/tmp/lists/samples.txt ); do
                    for mismatch in "${mismatches[@]}" ; do

                        if [ ! -f $raw_files/$tool/$database/hits/$subsample.$sample.$mismatch.fastq.fasta.tsv ] ; then 
                            sed "s/my_subsample/$subsample/g" $suppl_scripts/$pipeline.emu.sbatch \
                            | sed "s/my_sample/$sample/g" | sed "s/my_mismatch/$mismatch/g" | sed "s/my_qc_value/$QC/g" \
                            > $wd/tmp/sbatch/emu.$subsample.$sample.$mismatch.sbatch

                            sbatch $wd/tmp/sbatch/emu.$subsample.$sample.$mismatch.sbatch
                        fi 

                        wait_for_jobs_to_complete 20
                    done
                done
            done
            log "ALREADY FINISHED : $tool with $database database"
        fi
        wait_till_all_job_finished_with_name 0992_emu

        source /home/groups/VEO/tools/biopython/myenv/bin/activate

        python $suppl_scripts/utilities/combine_emu_output.py \
        -d $raw_files/$tool/$database/hits \
        -o $wd/$tool.$database.combined.tsv

        python $suppl_scripts/utilities/normalise_abundance_based_on_16S_copy.py \
        -i $wd/$tool.$database.combined.tsv \
        -o $wd/$tool.$database.combined.normalized.tsv \
        -r /veodata/03/databases/rrnDB/v5.10/rrnDB-5.10_pantaxa_stats_RDP.tsv 

        python $suppl_scripts/plots/0991_relative_abundance.py \
        -i $wd/$tool.$database.combined.tsv \
        -o $wd/$tool.$database.combined.tsv.png \
        --group-by genus \
        --top 25

        python $suppl_scripts/plots/0991_relative_abundance.py \
        -i $wd/$tool.$database.combined.normalized.tsv \
        -o $wd/$tool.$database.combined.normalized.tsv.png \
        --group-by genus \
        --top 25

        deactivate
    fi

    if [ $tool == "blast" ] ; then 
    if [ "$database" == "silva" ] || [ "$database" == "custom" ] ; then
        ## QC check for BLAST files 
            if [ ! -f $wd/tmp/blast.QC.tsv ] ; then 
                for subsample in "${subsamples[@]}"; do
                    for sample in $(cat $wd/tmp/lists/samples.txt ); do 
                        number_of_lines=$(wc -l $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv | awk '{print $1}' )
                        echo $subsample $sample $number_of_lines >> $wd/tmp/blast.QC.tsv
                    done
                done
            fi

        ## count the numbers of desired sequence 
            if [ ! -f $raw_files/count.tsv ] ; then
                for sample in $(cat $wd/tmp/lists/samples.txt ); do 
                    ## length_cov > 1200 and mismathces < 30 and e-values = 0

                        awk '$5 > 1200 && $6 < 200 &&  $11 == 0 {print $2}' \
                        $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv \
                        > $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv.filtered

                        count=$(  wc -l $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv.filtered | awk '{print $1}' )

                        sort $raw_files/blast_results/$subsample.$sample.$mismatch.fastq.fasta.tsv.filtered | uniq -c 
                        echo "----------"
                    echo $subsample $sample $count >> $raw_files/count.tsv
                done
            fi
    fi
    fi

    if [ "$tool" == "kraken2" ] ; then 
        if [ "$database" == "kraken2" ]; then 
            ## QC check for kraken2 files
            echo "subsample sample number_of_lines" | tr ' ' '\t' > $wd/tmp/kraken2.QC.tsv
            if [ ! -f $wd/tmp/kraken2.QC.tsv ] ; then 
                for subsample in "${subsamples[@]}"; do
                    for sample in $(cat $wd/tmp/lists/samples.txt ); do 
                        number_of_lines=$(wc -l $raw_files/kraken2/hits/$subsample.$sample.$mismatch.fastq.fasta.out | awk '{print $1}' )
                        echo $subsample $sample $number_of_lines | tr ' ' '\t' >> $wd/tmp/kraken2.QC.tsv
                    done
                done
            fi
        fi
    fi


############################################################################### 
## count the numbers

    if [ "$tool" == "kraken2" ]  && [ "$database" == "kraken2" ]; then 
        python3 $suppl_scripts/$pipeline.combine_to_mpa.py \
        -i $raw_files/kraken2/hits/*.formatted \
        -o $raw_files/kraken2/combined.mpa

        source /home/groups/VEO/tools/biopython/myenv/bin/activate
        python $suppl_scripts/0992_calculate_abundance_from_degenerative_primer.rarefaction.py \
        -d $raw_files/kraken2/hits/ \
        -o $raw_files/kraken2/rarefaction.png \
        -t $raw_files/kraken2/rarefaction.tsv \
        --html $raw_files/kraken2/rarefaction.html \
        --plateau_output $raw_files/kraken2/plateau_output.tsv \
        --max_samples 5000
        deactivate
    fi

    if [ $tool == "blast" ] && [ "$database" == "silva" ] || [ "$database" == "custom" ] ; then
        ## takes long (~OVERNIGHT) time
        if [ ! -d  $raw_files/count  ] ; then
            ( mkdir $raw_files/count ) > /dev/null 2>&1

            for subsample in "${subsamples[@]}"; do
                for sample in $(cat $wd/tmp/lists/samples.txt ); do 
                if [ ! -f $raw_files/count/$subsample.$sample.$mismatch.fastq.fasta.tsv.count ] ; then 
                    echo "creating and submitting sbatch for $barcode $barcode_RC"

                    sed "s/barcode_RC/$barcode_RC/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/0991_count_numbers.sbatch \
                    | sed "s/barcode/$barcode/g" | sed "s/subsample/$subsample/g" | sed "s/QC/$QC/g" \
                    > $raw_files/tmp/sbatch/count_numbers.$barcode.$barcode_RC.$subsample.sbatch

                    sbatch $raw_files/tmp/sbatch/count_numbers.$barcode.$barcode_RC.$subsample.sbatch
                fi
                done
            done 
        fi

        while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do  
            total_hits=$(awk 'NR>1 { sum += $2 } END { print sum }' $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.tsv)
            echo $barcode.$barcode_RC $total_hits | tee -a $raw_files/tmp/total_hits.$QC.$subsample.tsv
        done < $bp/"list.barcodes_all.FR.txt" 3< $bp/"list.barcodes_all.RC.txt"
    fi


    ## seventh checkpoint
    # exit 

###############################################################################
## @Swapnil: Below codes needs extensive modifications
## summarise the count
    # grep ">" tmp/parameters/$pipeline.query_sequence.2.fasta | sed 's/>//g' | sort -u > query.fasta.list

    # for subsample in "${subsamples[@]}"; do
    #     if [ ! -f $raw_files/final_tables/all.$subsample.tsv  ] ; then 
    #         ( mkdir $raw_files/final_tables ) > /dev/null 2>&1 
    #         if [ ! -f $raw_files/final_tables/final_count.$subsample.tsv ] ; then 
    #             ( rm $raw_files/count/*.$QC.fastq.fasta.2.$subsample.txt ) > /dev/null 2>&1 
    #             while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 
    #                 echo $barcode.$barcode_RC > $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt
    #                 for id in $(cat query.fasta.list ) ; do 
    #                     V1=$(grep -w "$id" $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.tsv | awk '{print $2}' )
    #                     if [ ! -z $V1 ]; then
    #                         echo $V1 >> $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt
    #                         else
    #                         echo 0 >> $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt
    #                     fi 
    #                 done
    #             done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt" 

    #             sed '1i\ids' query.fasta.list > query.fasta.list.tmp
    #             paste query.fasta.list.tmp $raw_files/count/*.$QC.fastq.fasta.2.$subsample.txt \
    #             > $raw_files/final_tables/final_count.$subsample.tsv
    #             rm query.fasta.list.tmp 
    #         fi 


    #         ## QC check for number of blast_total_hits in best_hits and number of lines in count 
    #             if [ ! -f $raw_files/tmp/blast.QC.tmp ] ;then 
    #                 echo -e "subsample\tbarcode.barcode_RC\tblast_total_hits\tblast_specific_hits\tsample_hits" > $raw_files/tmp/blast.QC.tmp
    #                 for subsample in "${subsamples[@]}"; do
    #                     while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do  
    #                         blast_total_hits=$(wc -l $raw_files/blast_results/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.$subsample.tsv | awk '{print $1}' )
    #                         blast_specific_hits=$(tail -n +2 $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.2.$subsample.txt | awk '{sum+=$1} END {print sum}' ) 
    #                         sample_hits=$(wc -l $raw_files/count/$barcode.$barcode_RC.$QC.fastq.fasta.best_hits.count.$subsample.tsv | awk '{print $1}' )
    #                         # echo brady $subsample $barcode.$barcode_RC $blast_total_hits $sample_hits
    #                         echo $subsample $barcode.$barcode_RC $blast_total_hits $blast_specific_hits $sample_hits >> $raw_files/tmp/blast.QC.tmp
    #                     done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
    #                 done 
    #             fi


    #         # barcodes2samples renaming
                
    #         while IFS= read -r line; do
    #             barcode=$(echo "$line" | awk '{print $1}')
    #             name=$(echo "$line" | awk '{print $2}')
    #             sed -i "s/$barcode/$name/g" $raw_files/final_tables/final_count.$subsample.tsv
    #             # sed -i "s/$barcode/$name/g" $raw_files/final_tables/final_count.rhizo.$subsample.tsv
    #         done < list.barcodes.names.txt
    #     fi

    #     if [ ! -f $raw_files/final_tables/all.$subsample.tsv ] ; then
    #         (rm $raw_files/final_tables/all.$subsample.tsv) > /dev/null 2>&1 
    #         ## create final table for Brady
    #         for header in $(head -1 $raw_files/final_tables/final_count.$subsample.tsv | sed 's/ids//g' | tr '\t' '\n' | sed '/^$/d' |  sort -u | sort -V ) ; do 
    #             echo $header
    #             awk -v header="$header" 'BEGIN {
    #                 FS="\t"
    #                 print header
    #             }
    #             NR==1 {
    #                 for (i=1; i<=NF; i++) {
    #                     if ($i == header) {
    #                         col[i] = 1
    #                     }
    #                 }
    #             }
    #             NR>1 {
    #                 row_sum = 0
    #                 for (i=1; i<=NF; i++) {
    #                     if (col[i]) {
    #                         row_sum += $i
    #                     }
    #                 }
    #                 printf "%s\n", row_sum
    #             }' $raw_files/final_tables/final_count.$subsample.tsv > $raw_files/final_tables/$header.tsv

    #             touch $raw_files/final_tables/all.$subsample.tsv
    #             paste $raw_files/final_tables/all.$subsample.tsv $raw_files/final_tables/$header.tsv > $raw_files/final_tables/all.tmp
    #             mv $raw_files/final_tables/all.tmp $raw_files/final_tables/all.$subsample.tsv
    #             rm $raw_files/final_tables/$header.tsv 
    #         done 

    #         sed '1i\ids' query.fasta.list > query.fasta.list.tmp
    #         paste query.fasta.list.tmp $raw_files/final_tables/all.$subsample.tsv > $raw_files/final_tables/all.2.tsv
    #         sed 's/\t\t/\t/g' $raw_files/final_tables/all.2.tsv > $raw_files/final_tables/all.$subsample.tsv 
    #         rm query.fasta.list.tmp
    #         rm $raw_files/final_tables/all.2.tsv
    #     fi
    # done


###############################################################################
## create figure
    source /home/groups/VEO/tools/python/pandas/bin/activate

    for subsample in "${subsamples[@]}"; do
        echo "creating figure for $subsample for brady"
        ## first convert the table to percentage
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_table_to_percetage.py \
        -i $raw_files/final_tables/all.$subsample.tsv \
        -o $raw_files/final_tables/all.$subsample.perc.tsv
        ## create actual figure
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/stacked_column_chart.py \
        -i $raw_files/final_tables/all.$subsample.perc.tsv \
        -o $raw_files/final_tables/all.$subsample.perc.tsv.png
    done 
###############################################################################
	log "finished : $pipeline for $sublist" && clean
###############################################################################



# ## QC: count the number of reads  
#     if [ ! -f $raw_files/tmp/total_number_of_reads.$QC.txt ] ; then 
#         for subsample in "${subsamples[@]}"; do
#             while IFS= read -r barcode && IFS= read -r barcode_RC <&3; do 

#                 number_of_reads_ids_in_FR=$(wc -l $raw_files/tmp/lists/list.$barcode.read_ids.$subsample.txt | awk '{print $1}')
#                 number_of_reads_ids_in_RC=$(wc -l $raw_files/tmp/lists/list.$barcode_RC.read_ids.$subsample.txt | awk '{print $1}')
#                 number_of_total_read_ids=$(( $number_of_reads_ids_in_FR + $number_of_reads_ids_in_RC )) ## here duplicates are not removed

#                 lines=$(wc -l $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$subsample.fastq | awk '{print $1}' )
#                 non_duplicate_reads=$(( $lines / 4 ))

#                 lines_10=$(wc -l $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$QC.$subsample.fastq | awk '{print $1}')
#                 reads_10=$(( $lines_10 / 4 ))

#                 lines_in_fasta10=$(wc -l $raw_files/read_ids_extracted_fastq/$barcode.$barcode_RC.$QC.fastq.$subsample.fasta | awk '{print $1}')
#                 reads_in_fasta10=$(( $lines_in_fasta10 / 2 ))

#                 echo "$barcode && $barcode_RC : $number_of_total_read_ids $non_duplicate_reads $reads_10 $reads_in_fasta10" 
#                 echo "$barcode && $barcode_RC : $number_of_total_read_ids $non_duplicate_reads $reads_10 $reads_in_fasta10" >> $raw_files/tmp/total_number_of_reads.$QC.txt

#             done < "list.barcodes_all.FR.txt" 3< "list.barcodes_all.RC.txt"
#         done
#     fi
#     log "FINISHED : QC: count the number of reads"
#     ## checkpoint for reads
#     # exit 