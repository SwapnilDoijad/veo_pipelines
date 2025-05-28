#!/bin/bash
#SBATCH --job-name 0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
#SBATCH --partition=standard,long
#SBATCH --output results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.out
#SBATCH --error results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
#SBATCH --exclusive
#SBATCH --mail-user=your_email@example.com
###############################################################################
## notes: 
	## if directory exists step will not work with this script, as several parallel jobs will be running \
	## and one of the script will create the first directory and other will just skip 
###############################################################################
## header 
	pipeline=0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
	sublist=$wd/tmp/lists/ABC
	fastq_path=$( grep my_fastq $parameters | awk '{print $2}' )
	minimum_length=$( grep my_minimum_length $parameters | awk '{print $2}' )
	maximum_length=$( grep my_maximum_length $parameters | awk '{print $2}' )
	phred=$(grep my_phred $parameters | awk '{print $2}')
	final_read_length=$(grep my_final_read_length $parameters | awk '{print $2}')
	subsample=$(grep my_subsample $parameters | awk '{print $2}')
	subsample_final=$(grep my_final_subsample $parameters | awk '{print $2}')
	masking=$(grep my_masking $parameters | awk '{print $2}')
	remove_contaminant_reads=$(grep my_remove_contaminant_reads $parameters | awk '{print $2}')
	kmer_size=$(grep my_kmer_size $parameters | awk '{print $2}')
	mkdir -p $wd/tmp/tmp/ > /dev/null 2>&1

	log "starting $pipeline"
	log	"sublist: $sublist"
	log	"fastq_path: $fastq_path"
	log	"minimum_length: $minimum_length"
	log	"maximum_length: $maximum_length"
	log	"phred: $phred"
	log "remove_contaminant_reads: $remove_contaminant_reads"
	log	"final_read_length: $final_read_length"
	log	"subsample: $subsample"
	log	"subsample_final: $subsample_final"
	log	"masking: $masking"
	log	"kmer_size: $kmer_size"
###############################################################################
## 01 filter fastq for quality and length (min + max)

		mkdir $raw_files/my_fastq_masked_filtered_Q > /dev/null 2>&1

		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 

		if [ ! -f $raw_files/fastq_count_before_after_filter.tsv ] && [ $masking = "Yes" ]; then 
			echo "#id reads_in_orignal_fastq reads_after_masking reads_after_filtering" \
			| tr ' ' '\t' > $raw_files/fastq_count_before_after_filter.tsv
			elif [ ! -f $raw_files/fastq_count_before_after_filter.tsv ] && [ $masking = "No" ]; then
			echo "#id reads_in_orignal_fastq reads_after_filtering" \
			| tr ' ' '\t' > $raw_files/fastq_count_before_after_filter.tsv
		fi

		for i in $( cat $sublist ); do 
			if [ ! -f $raw_files/my_fastq_masked_filtered_Q/$i.fastq.gz ] ; then
				log  "STARTED : filtering for $i"
	
				if [ $masking = "Yes" ]; then 
					log "masking of bases with read quality less than 10"
					## masking of bases with read quality less than 10
					/home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk seq -q 10 -n N \
					$fastq_path/$i.fastq.gz \
					| gzip > $raw_files/my_fastq_masked_filtered_Q/$i.masked.fastq.gz

					## filter out masked reads if carries 'N' more than p (percentage of masked bases)
					## out: $i.masked.filtered_"$p".0.tsv
					python3 $suppl_scripts/0401_filter_masked_reads.py \
					-i $raw_files/my_fastq_masked_filtered_Q/$i.masked.fastq.gz \
					-o $raw_files/my_fastq_masked_filtered_Q/$i.masked.filtered.fastq.gz \
					-p 10 

					current_fastq=$raw_files/my_fastq_masked_filtered_Q/$i.masked.filtered.fastq.gz
					reads_after_masking=$( count_reads_from_fastq $raw_files/my_fastq_masked_filtered_Q/$i.masked.filtered.fastq.gz )
					else
					current_fastq=$fastq_path/$i.fastq.gz
				fi

				## filtering for quality and length (min + max)
				zcat $current_fastq \
				| chopper -q $phred --threads $SLURM_CPUS_PER_TASK --minlength $minimum_length --maxlength $maximum_length \
				| gzip > $raw_files/my_fastq_masked_filtered_Q/$i.fastq.gz

				## count reads more than anticipated length
				python3 $scripts_for_users_path/supplementary_scripts/0401_count_reads_more_than_anticipated.py \
				-i $current_fastq \
				-o $wd/tmp/tmp/$i.fastq.gz.tsv \
				-l $maximum_length

				reads_in_orignal_fastq=$( count_reads_from_fastq $fastq_path/$i.fastq.gz )
				reads_after_filtering=$( count_reads_from_fastq $raw_files/my_fastq_masked_filtered_Q/$i.fastq.gz )
				# reads_more_than_anticipated_length=$( awk -F' ' '{print $NF}' $wd/tmp/tmp/$i.fastq.gz.tsv )
				# reads_less_than_desired_QC=$(( $reads_in_orignal_fastq - $reads_after_masking - $reads_after_filtering - $reads_more_than_anticipated_length ))

				if [ $masking = "Yes" ]; then 
					echo "$i $reads_in_orignal_fastq $reads_after_filtering $reads_after_masking " | tr ' ' '\t' | tee -a  $raw_files/fastq_count_before_after_filter.tsv
					else
					echo "$i $reads_in_orignal_fastq $reads_after_filtering" | tr ' ' '\t' | tee -a  $raw_files/fastq_count_before_after_filter.tsv
				fi

				log  "FINISHED : filtering for $i"
				else 
				log "ALREADY FINISHED : filtering for $i"
			fi
		done
		conda deactivate

###############################################################################
## 02 subsample fastq

	mkdir -p $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample" > /dev/null 2>&1
	for i in $(cat $sublist); do 
		if [ $subsample != "No" ] ; then
			source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 


				if [ ! -f $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"/$i.fastq.gz ] ; then 
					log "STARTED : subsampling for $i"
					rasusa -i $raw_files/my_fastq_masked_filtered_Q/$i.fastq.gz \
					-n $subsample \
					-o $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
					-O g

					log "FINISHED : subsampling for $i"
					else
					log "ALREADY FINISHED : subsampling for $i"
				fi


			else
			log "NO SUBSAMPLING : $i : copying $i.fastq.gz as it is"
			cp $raw_files/my_fastq_masked_filtered_Q/$i.fastq.gz $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"/$i.fastq.gz
		fi
	done

###############################################################################
	if [ $remove_contaminant_reads = "Yes" ]; then
	###############################################################################
	## 03 fastq to fasta
			mkdir $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta > /dev/null 2>&1
			for i in $(cat $sublist); do
				if [ ! -f $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta/$i.fasta ] ; then 
					log "STARTED : fastq to fasta for $i"

					python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastq2fasta.py \
					-i $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
					-o $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta/$i.fasta

					sed -i 's/ .*//g' $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta/$i.fasta
					sed -i 's/\t.*//g' $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta/$i.fasta
					
					log "FINISHED : fastq to fasta for $i"
					else
					log "ALREADY FINISHED : fastq to fasta for $i"
				fi
			done

	###############################################################################
	## 04 split fasta of every barcode to single file 

			mkdir $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual > /dev/null 2>&1
			for i in $(cat $sublist); do 
				if [ ! -d $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual/$i ] ; then 
					log "STARTED : spliting fasta to individual reads for $i"

					mkdir $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual/$i > /dev/null 2>&1

					bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
					-i $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta/$i.fasta \
					-o $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual/$i/

					log "FINISHED : spliting fasta to individual reads for $i"
					else
					log "ALREADY FINISHED : spliting fasta to individual reads for $i"
				fi 
			done

	############################################################################### 
	## 05 k-mer count by JellyFish
			jellyFish="$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish"
			for i in $( cat $sublist ); do 
				mkdir -p $jellyFish/$i > /dev/null 2>&1
				log "checking k-mer count by JellyFish for $i"
				for sequence in $(ls $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual/$i/ ); do 
					if [ ! -f $jellyFish/$i/$sequence.jf.dump ] ; then 

						## -s 1M : using a hash with 1 million elements
						## -m 4 : k-mer size 4
						/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish \
						count -m $kmer_size -s 1M -t $SLURM_CPUS_PER_TASK \
						-o $jellyFish/$i/$sequence.jf \
						$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual/$i/$sequence 

						/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish dump \
						-c $jellyFish/$i/$sequence.jf \
						> $jellyFish/$i/$sequence.jf.dump
					fi
				done 
			done 
	###############################################################################
	## 06 matrix from kmer counts + tsne plot stat
		## $raw_files/jelly_fish_matrix/$i/matrix.tsv take long time 

		matrix=$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix
		mkdir $matrix > /dev/null 2>&1
		source /home/groups/VEO/tools/biopython/myenv/bin/activate
		for i in $( cat $sublist ); do 
			if [ ! -f $matrix/$i/matrix.tsv ] ; then 
				mkdir $matrix/$i > /dev/null 2>&1

				log "STARTED: creating matrix from kmer counts for $i"
				if [ ! -f $matrix/$i/matrix.tsv ]; then
					# python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_merge_data_by_dask.faster.py \
					python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_merge_data_by_dask.py \
					-i $jellyFish/$i \
					-o $matrix/$i/matrix.tsv  \
					& my_pid=$!
					get_resource_stat $my_pid $wd/tmp/resource_log/$id.0401_merge_data_by_dask.tsv 

					sed -i 's/@//g' $matrix/$i/matrix.tsv
				fi

				python $suppl_scripts/0401_create_a_tsne_plot_by_Zscore_and_GC.py \
				-g $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
				-m $matrix/$i/matrix.tsv \
				-o $matrix/$i

									## depreciated 
										# log "STARTED: creating tSNE plot for $i"
										# ## output is $wd/out/$i/inlier.tsv
										# python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_create_a_tsne_plot.py \
										# -i $matrix/$i/matrix.tsv \
										# -o $matrix/$i

										# awk '{print $1}' $matrix/$i/inlier.tsv | sed 's/@//g' > $matrix/$i/inlier.tsv.read_ids_tmp

										# log "STARTED: idenifying outlier based on GC content for $i"
										# python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_filter_reads_based_on_GC.py \
										# -i $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
										# -o $matrix/$i 

										# ## remove outliers identified by GC content
										# grep -vFf $matrix/$i/iqr_gc_content_outliers.txt $matrix/$i/inlier.tsv.read_ids_tmp | sort | uniq > $matrix/$i/inlier.tsv.read_ids

										# rm $matrix/$i/inlier.tsv.read_ids_tmp

				## identify outlier based on the average deviation of the k-mer profile to each other. 
					## This script identifies outlier reads based on k-mer deviations from the average k-mer profile using \
					## an automatically determined threshold from the density drop-off point. Outputs are clearly labeled \
					## and saved to the provided directory for further analysis.
				python $suppl_scripts/0401_identify_outlier_based_on_eucl_dist.py \
				--input_file $matrix/$i/matrix.tsv \
				--output_dir $matrix/$i

				log "FINISHED: creating matrix from kmer counts for $i"
				else
				log "ALREADY FINISHED: creating matrix from kmer counts for $i"
			fi
		done 
		deactivate

	###############################################################################
	## 07 write out $reads/$i.fastq.gz

		reads=$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads
		mkdir $reads > /dev/null 2>&1
		source /home/groups/VEO/tools/biopython/myenv/bin/activate
		for i in $( cat $sublist ); do
			if [ ! -f $reads/$i.fastq.gz ] ; then 
				log "STARTED: writing inlier reads for $i"

				python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/extract_reads_from_fastq.py \
				-i $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
				-o $reads/$i.fastq.gz \
				-l $matrix/$i/tSNE_inlier.tsv.read_ids

				log "FINISHED: writing inlier reads for $i"
				else
				log "ALREADY FINISHED: writing inlier reads for $i"
			fi 
		done
		deactivate

	###############################################################################
	fi 
###############################################################################
## 08 long reads to short reads
	if [ $remove_contaminant_reads = "Yes" ]; then
		reads=$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads
		ReadLength=$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"
		else
		reads=$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"
		ReadLength=$raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_"$final_read_length"
	fi
	mkdir $ReadLength > /dev/null 2>&1

	for i in $(cat $sublist ); do
		if [ ! -f $ReadLength/$i.fastq.gz ] ; then 
			log "STARTED: converting long reads to short reads for $i"

			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/long_reads_to_short_reads.py \
			-i $reads/$i.fastq.gz \
			-o $ReadLength/$i.fastq.gz \
			-l $final_read_length

			log "FINISHED: converting long reads to short reads for $i"
			else
			log "ALREADY FINISHED: converting long reads to short reads for $i"
		fi 
	done
###############################################################################
## 09 subsample to $subsample_final
	if [ $subsample_final != "No" ] ; then
		log "STARTED: subsampling to $subsample_final"

		subsampled_final_reads="$ReadLength"_subsampled"$subsample_final"reads
		mkdir $subsampled_final_reads > /dev/null 2>&1

		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 
		for i in $(cat $sublist ); do
			if [ ! -f $subsampled_final_reads/$i.fastq.gz ] ; then 
				log "STARTED: subsampling to $subsample_final for $i"

				rasusa \
				-i $ReadLength/$i.fastq.gz \
				-n $subsample_final \
				-o $subsampled_final_reads/$i.fastq.gz \
				-O g

				log "FINISHED: subsampling to $subsample_final for $i"
				else
				log "ALREADY FINISHED: subsampling to $subsample_final for $i"
			fi 
		done
		conda deactivate
		
		else
		log "NO SUBSAMPLING for $i"
	fi
###############################################################################
## 10 masking of bases with read quality less than 20
	if [ $masking = "Yes" ]; then 
		subsampled_final_reads_masked="$subsampled_final_reads"_masked
		mkdir $subsampled_final_reads_masked > /dev/null 2>&1

		for i in $(cat "$sublist"); do 
			/home/groups/VEO/tools/seqtk/v1.4/seqtk/seqtk seq -q 20 -n N \
			$subsampled_final_reads/$i.fastq.gz \
			| gzip > $subsampled_final_reads_masked/$i.fastq.gz
		done
	fi 
###############################################################################
## 10 create final stat
	for i in $(cat "$sublist"); do 
		# Calculate counts
		my_fastq_masked_filtered_Q_reads=$(count_reads_from_fastq "$raw_files/my_fastq_masked_filtered_Q/$i.fastq.gz")
		my_fastq_masked_filtered_Q_subsampled=$(count_reads_from_fastq "$raw_files/my_fastq_masked_filtered_Q_subsampled${subsample}/$i.fastq.gz")
		my_fastq_masked_filtered_Q_subsampled_fasta=$(count_number_of_sequences_in_fasta "$raw_files/my_fastq_masked_filtered_Q_subsampled${subsample}_fasta/$i.fasta")
		my_fastq_masked_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads=$(count_reads_from_fastq "$raw_files/my_fastq_masked_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads/$i.fastq.gz")
		my_fastq_masked_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered=$(count_reads_from_fastq "$raw_files/my_fastq_masked_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads_filtered${final_read_length}/$i.fastq.gz")
		if [ $subsample != "No" ] ; then
			my_fastq_masked_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered_subsampled=$(count_reads_from_fastq "$raw_files/my_fastq_masked_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads_filtered${final_read_length}_subsampled${subsample_final}reads/$i.fastq.gz")
			else
			my_fastq_masked_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered_subsampled=na
		fi
		# Append results to summary file
		echo "$i $my_fastq_masked_filtered_Q_reads $my_fastq_masked_filtered_Q_subsampled $my_fastq_masked_filtered_Q_subsampled_fasta $my_fastq_masked_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads $my_fastq_masked_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered $my_fastq_masked_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered_subsampled" | tr ' ' '\t' | tee -a "$raw_files/summary.${final_read_length}.tsv"	
	done

###############################################################################
## 2024-12-28 10:36:16 Extra
	# source /home/groups/VEO/tools/biopython/myenv/bin/activate
	
	# python $suppl_scripts/0401_filter_read_ids_based_on_tSNE_values.py \
	# -i $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix/tsne_coordinates.tsv
	# -o $raw_files/my_fastq_masked_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix/tsne_coordinates.tSNE_based_filtered.tsv
	# -T1 "35" \
	# -T2 "-30"

	# deactivate
