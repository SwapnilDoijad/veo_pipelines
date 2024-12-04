#!/bin/bash
#SBATCH --job-name 0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
#SBATCH --partition=standard,long
#SBATCH --output results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.out
#SBATCH --error results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
#SBATCH --nodes=1
#SBATCH --ntasks=1
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
	sublist=results/$pipeline/tmp/lists/ABC
	fastq_path=$( grep my_fastq $parameters | awk '{print $2}' )
	minimum_length=$( grep my_minimum_length $parameters | awk '{print $2}' )
	maximum_length=$( grep my_maximum_length $parameters | awk '{print $2}' )
	phred=$(grep my_phred $parameters | awk '{print $2}')
	final_read_length=$(grep my_final_read_length $parameters | awk '{print $2}')
	subsample=$(grep my_subsample $parameters | awk '{print $2}')
	subsample_final=$(grep my_final_subsample $parameters | awk '{print $2}')
	mkdir -p $wd/tmp/tmp/ > /dev/null 2>&1

	log "starting $pipeline"
	log	"sublist: $sublist"
	log	"fastq_path: $fastq_path"
	log	"minimum_length: $minimum_length"
	log	"maximum_length: $maximum_length"
	log	"phred: $phred"
	log	"final_read_length: $final_read_length"
	log	"subsample: $subsample"
	log	"subsample_final: $subsample_final"
# ###############################################################################
# ## 01 filter fastq for quality and length (min + max)

# 		mkdir $raw_files/my_fastq_filtered_Q > /dev/null 2>&1

# 		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 

# 		if [ ! -f $raw_files/fastq_count_before_after_filter.tsv ] ; then 
# 			echo "#id original_count filtered_count reads_less_than_desired_QC reads_more_than_anticipated_length" \
# 			| tr ' ' '\t' > $raw_files/fastq_count_before_after_filter.tsv
# 		fi

# 		for i in $( cat $sublist ); do 
# 			if [ ! -f $raw_files/my_fastq_filtered_Q/$i.fastq.gz ] ; then
# 				log  "STARTED : filtering for $i"

# 				zcat $fastq_path/$i.fastq.gz \
# 				| chopper -q $phred --threads $SLURM_CPUS_PER_TASK --minlength $minimum_length --maxlength $maximum_length \
# 				| gzip > $raw_files/my_fastq_filtered_Q/$i.fastq.gz

# 				python3 $scripts_for_users_path/supplementary_scripts/0401_count_reads_more_than_anticipated.py \
# 				-i $fastq_path/$i.fastq.gz \
# 				-o $wd/tmp/tmp/$i.fastq.gz.tsv \
# 				-l $maximum_length

# 				original_fastq_count=$( count_reads_from_fastq $fastq_path/$i.fastq.gz )
# 				filtered_fastq_count=$( count_reads_from_fastq $raw_files/my_fastq_filtered_Q/$i.fastq.gz )
# 				reads_more_than_anticipated_length=$( awk -F' ' '{print $NF}' $wd/tmp/tmp/$i.fastq.gz.tsv )
# 				reads_less_than_desired_QC=$(( $original_fastq_count - $filtered_fastq_count - $reads_more_than_anticipated_length ))
# 				echo "$i $original_fastq_count $filtered_fastq_count $reads_less_than_desired_QC $reads_more_than_anticipated_length" | tr ' ' '\t' | tee -a  $raw_files/fastq_count_before_after_filter.tsv

# 				log  "FINISHED : filtering for $i"
# 				else 
# 				log "ALREADY FINISHED : filtering for $i"
# 			fi
# 		done
# 		conda deactivate

# ###############################################################################
# ## 02 subsample fastq

# 		mkdir -p $raw_files/my_fastq_filtered_Q_subsampled"$subsample" > /dev/null 2>&1
# 		if [ $subsample != "no_subsample" ] ; then
# 			source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 

# 			for i in $(cat $sublist); do 
# 				if [ ! -f $raw_files/my_fastq_filtered_Q_subsampled"$subsample"/$i.fastq.gz ] ; then 
# 					log "STARTED : subsampling for $i"
# 					rasusa -i $raw_files/my_fastq_filtered_Q/$i.fastq.gz \
# 					-n $subsample \
# 					-o $raw_files/my_fastq_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
# 					-O g

# 					log "FINISHED : subsampling for $i"
# 					else
# 					log "ALREADY FINISHED : subsampling for $i"
# 				fi
# 			done

# 			else
# 			cp $raw_files/my_fastq_filtered_Q/$i.fastq.gz $raw_files/my_fastq_filtered_Q_subsampled"$subsample"/$i.fastq.gz
# 		fi

# ###############################################################################
# ## 03 fastq to fasta
# 		mkdir $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta > /dev/null 2>&1
# 		for i in $(cat $sublist); do
# 			if [ ! -f $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta/$i.fasta ] ; then 
# 				log "STARTED : fastq to fasta for $i"

# 				python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastq2fasta.py \
# 				-i $raw_files/my_fastq_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
# 				-o $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta/$i.fasta

# 				sed -i 's/ .*//g' $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta/$i.fasta
# 				sed -i 's/\t.*//g' $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta/$i.fasta
				
# 				log "FINISHED : fastq to fasta for $i"
# 				else
# 				log "ALREADY FINISHED : fastq to fasta for $i"
# 			fi
# 		done

# ###############################################################################
# ## 04 split fasta of every barcode to single file 

# 		mkdir $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual > /dev/null 2>&1
# 		for i in $(cat $sublist); do 
# 			if [ ! -d $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual/$i ] ; then 
# 				log "STARTED : spliting fasta to individual reads for $i"

# 				mkdir $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual/$i > /dev/null 2>&1

# 				bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
# 				-i $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta/$i.fasta \
# 				-o $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual/$i/

# 				log "FINISHED : spliting fasta to individual reads for $i"
# 				else
# 				log "ALREADY FINISHED : spliting fasta to individual reads for $i"
# 			fi 
# 		done

# ############################################################################### 
# ## 05 k-mer count by JellyFish
# 		jellyFish="$raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish"
# 		for i in $( cat $sublist ); do 
# 			mkdir -p $jellyFish/$i > /dev/null 2>&1
# 			log "checking k-mer count by JellyFish for $i"
# 			for sequence in $(ls $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual/$i/ ); do 
# 				if [ ! -f $jellyFish/$i/$sequence.jf.dump ] ; then 
# 					log "STARTED : k-mer count by JellyFish for $i : $sequence "

# 					## -s 1M : using a hash with 1 million elements
# 					## -m 4 : k-mer size 4
# 					/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish \
# 					count -m 4 -s 1M -t $SLURM_CPUS_PER_TASK \
# 					-o $jellyFish/$i/$sequence.jf \
# 					$raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual/$i/$sequence 

# 					/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish dump \
# 					-c $jellyFish/$i/$sequence.jf \
# 					> $jellyFish/$i/$sequence.jf.dump

# 					log "FINISHED : k-mer count by JellyFish for $i : $sequence "
# 				fi
# 			done 
# 		done 
# ###############################################################################
# ## 06 matrix from kmer counts + tsne plot stat
# 	## $raw_files/jelly_fish_matrix/$i/matrix.tsv take long time 

# 	matrix=$raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix
# 	mkdir $matrix > /dev/null 2>&1
# 	source /home/groups/VEO/tools/biopython/myenv/bin/activate
# 	for i in $( cat $sublist ); do 
# 		if [ ! -f $matrix/$i/matrix.tsv ] ; then 
# 			mkdir $matrix/$i > /dev/null 2>&1

# 			log "STARTED: creating matrix from kmer counts for $i"
# 			# python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_merge_data_by_dask.faster.py \
# 			python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_merge_data_by_dask.py \
# 			-i $jellyFish/$i \
# 			-o $matrix/$i/matrix.tsv

# 			log "STARTED: creating tSNE plot for $i"
# 			## output is $wd/out/$i/inlier.tsv
# 			python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_create_a_tsne_plot.py \
# 			-i $matrix/$i/matrix.tsv \
# 			-o $matrix/$i

# 			awk '{print $1}' $matrix/$i/inlier.tsv | sed 's/@//g' > $matrix/$i/inlier.tsv.read_ids

# 			log "FINISHED: creating matrix from kmer counts for $i"
# 			else
# 			log "ALREADY FINISHED: creating matrix from kmer counts for $i"
# 		fi
# 	done 
# 	deactivate

# ###############################################################################
# ## 07 write $wd/out/$i/inlier.tsv.read_ids

# 	reads=$raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads
# 	mkdir $reads > /dev/null 2>&1
# 	source /home/groups/VEO/tools/biopython/myenv/bin/activate
# 	for i in $( cat $sublist ); do
# 		if [ ! -f $reads/$i.fastq.gz ] ; then 
# 			log "STARTED: writing inlier reads for $i"

# 			awk '{print $1}' $matrix/$i/inlier.tsv | sed 's/@//g' > $matrix/$i/inlier.tsv.read_ids

# 			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/extract_reads_from_fastq.py \
# 			-i $raw_files/my_fastq_filtered_Q_subsampled"$subsample"/$i.fastq.gz \
# 			-o $reads/$i.fastq.gz \
# 			-l $matrix/$i/inlier.tsv.read_ids

# 			log "FINISHED: writing inlier reads for $i"
# 			else
# 			log "ALREADY FINISHED: writing inlier reads for $i"
# 		fi 
# 	done
# 	deactivate

# ###############################################################################
# ## 08 long reads to short reads
# 	ReadLength=$raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"
# 	mkdir $ReadLength > /dev/null 2>&1
# 	for i in $(cat $sublist ); do
# 		if [ ! -f $ReadLength/$i.fastq.gz ] ; then 
# 			log "STARTED: converting long reads to short reads for $i"

# 			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/long_reads_to_short_reads.py \
# 			-i $reads/$i.fastq.gz \
# 			-o $ReadLength/$i.fastq.gz \
# 			-l $final_read_length

# 			log "FINISHED: converting long reads to short reads for $i"
# 			else
# 			log "ALREADY FINISHED: converting long reads to short reads for $i"
# 		fi 
# 	done
# ###############################################################################
# ## 09 subsampel to $subsample_final

# 	subsampled_final_reads=$raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"_subsampled"$subsample_final"reads
# 	mkdir $subsampled_final_reads > /dev/null 2>&1
# 	source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 
# 	for i in $(cat $sublist ); do
# 		if [ ! -f $subsampled_final_reads/$i.fastq.gz ] ; then 
# 			log "STARTED: subsampling to $subsample_final for $i"

# 			rasusa \
# 			-i $ReadLength/$i.fastq.gz \
# 			-n $subsample_final \
# 			-o $subsampled_final_reads/$i.fastq.gz \
# 			-O g

# 			log "FINISHED: subsampling to $subsample_final for $i"
# 			else
# 			log "ALREADY FINISHED: subsampling to $subsample_final for $i"
# 		fi 
# 	done
# 	deactivate

###############################################################################
## 10 create final stat
	# for i in $(cat $sublist); do 
	# 	my_fastq_filtered_Q_reads=$( count_reads_from_fastq $raw_files/my_fastq_filtered_Q/$i.fastq.gz)
	# 	my_fastq_filtered_Q_subsampled"$subsample"=$( count_reads_from_fastq  $raw_files/my_fastq_filtered_Q_subsampled"$subsample"/$i.fastq.gz )
	# 	my_fastq_filtered_Q_subsampled"$subsample"_fasta=$(count_number_of_sequences_in_fasta $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta/$i.fasta )
	# 	my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads=$( count_reads_from_fastq $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads/$i.fastq.gz )
	# 	my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"=$( count_reads_from_fastq $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"/$i.fastq.gz )
	# 	my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"_subsampled"$subsample_final"reads=$( count_reads_from_fastq $raw_files/my_fastq_filtered_Q_subsampled"$subsample"_fasta_individual_jellyFish_matrix_reads_filtered"$final_read_length"_subsampled"$subsample_final"reads/$i.fastq.gz )
	# 	echo "$i $my_fastq_filtered_Q_reads $my_fastq_filtered_Q_subsampled$subsample $my_fastq_filtered_Q_subsampled${subsample}_fasta $my_fastq_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads $my_fastq_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads_filtered${final_read_length} $my_fastq_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads_filtered${final_read_length}_subsampled${subsample_final}reads" | tee -a $raw_files/summary.$final_read_length.tsv
	# done 

for i in $(cat "$sublist"); do 
    # Calculate counts
    my_fastq_filtered_Q_reads=$(count_reads_from_fastq "$raw_files/my_fastq_filtered_Q/$i.fastq.gz")
    my_fastq_filtered_Q_subsampled=$(count_reads_from_fastq "$raw_files/my_fastq_filtered_Q_subsampled${subsample}/$i.fastq.gz")
    my_fastq_filtered_Q_subsampled_fasta=$(count_number_of_sequences_in_fasta "$raw_files/my_fastq_filtered_Q_subsampled${subsample}_fasta/$i.fasta")
    my_fastq_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads=$(count_reads_from_fastq "$raw_files/my_fastq_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads/$i.fastq.gz")
    my_fastq_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered=$(count_reads_from_fastq "$raw_files/my_fastq_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads_filtered${final_read_length}/$i.fastq.gz")
    my_fastq_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered_subsampled=$(count_reads_from_fastq "$raw_files/my_fastq_filtered_Q_subsampled${subsample}_fasta_individual_jellyFish_matrix_reads_filtered${final_read_length}_subsampled${subsample_final}reads/$i.fastq.gz")

    # Append results to summary file
    echo "$i $my_fastq_filtered_Q_reads $my_fastq_filtered_Q_subsampled $my_fastq_filtered_Q_subsampled_fasta $my_fastq_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads $my_fastq_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered $my_fastq_filtered_Q_subsampled_fasta_individual_jellyFish_matrix_reads_filtered_subsampled" | tr ' ' '\t' | tee -a "$raw_files/summary.${final_read_length}.tsv"
done

###############################################################################