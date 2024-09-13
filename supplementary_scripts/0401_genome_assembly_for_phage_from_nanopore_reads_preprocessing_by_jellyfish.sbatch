#!/bin/bash
#SBATCH --job-name 0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
#SBATCH --partition=interactive
#SBATCH --output results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.out
#SBATCH --error results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=your_email@example.com
###############################################################################
## notes: 
	## if directory exists step will not work with this script, as several parallel jobs will be running \
	## and one of the script will create the directory and other will just skip 
###############################################################################
## header 
	pipeline=0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
	sublist=results/$pipeline/tmp/lists/ABC
	fastq_path=$( grep my_fastq $parameters | awk '{print $2}' )
	minimum_lenght=$( grep my_minimum_lenght $parameters | awk '{print $2}' )
	maximum_lenght=$( grep my_maximum_lenght $parameters | awk '{print $2}' )
	phred=$(grep my_phred $parameters | awk '{print $2}')
	final_read_length=$(grep my_final_read_length $parameters | awk '{print $2}')
	subsample=$(grep my_subsample $parameters | awk '{print $2}')
	mkdir -p $wd/tmp/tmp/ > /dev/null 2>&1

	log "starting $pipeline"
	log	"sublist: $sublist"
	log	"fastq_path: $fastq_path"
	log	"minimum_lenght: $minimum_lenght"
	log	"maximum_lenght: $maximum_lenght"
	log	"phred: $phred"
	log	"final_read_length: $final_read_length"
	log	"subsample: $subsample"
	
###############################################################################
## 01 filter fastq for quality and length (min + max)

		mkdir $raw_files/my_fastq_filtered_Q > /dev/null 2>&1

		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 

		for i in $( cat $sublist ); do 
			if [ ! -f $raw_files/my_fastq_filtered_Q/$i.fastq.gz ] ; then
				log  "STARTED : filtering for $i"

				zcat $fastq_path/$i.fastq.gz \
				| chopper -q $phred --threads $SLURM_CPUS_PER_TASK --minlength $minimum_lenght --maxlength $maximum_lenght \
				| gzip > $raw_files/my_fastq_filtered_Q/$i.fastq.gz

				python3 $scripts_for_users_path/supplementary_scripts/0401_count_reads_more_than_anticipated.py \
				-i $fastq_path/$i.fastq.gz \
				-o $wd/tmp/tmp/$i.fastq.gz.tsv \
				-l $maximum_lenght

				original_fastq_count=$( count_reads_from_fastq $fastq_path/$i.fastq.gz )
				filtered_fastq_count=$( count_reads_from_fastq $raw_files/my_fastq_filtered_Q/$i.fastq.gz )
				reads_more_than_anticipated_length=$( awk -F' ' '{print $NF}' $wd/tmp/tmp/$i.fastq.gz.tsv )
				reads_less_than_desired_QC=$(( $original_fastq_count - $filtered_fastq_count - $reads_more_than_anticipated_length ))
				echo "$i $original_fastq_count $filtered_fastq_count $reads_less_than_desired_QC $reads_more_than_anticipated_length" | tee -a  $raw_files/fastq_count_before_after_filter.tsv

				log  "FINISHED : filtering for $i"
				else 
				log "ALREADY FINISHED : filtering for $i"
			fi
		done
		conda deactivate

###############################################################################
## 02 subsample fastq

		mkdir $raw_files/my_fastq_filtered_Q_subsampled > /dev/null 2>&1
		if [ $subsample != "no_subsample" ] ; then
			source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate rasusa_v0.7.1 

			for i in $(cat $sublist); do 
				if [ ! -f $raw_files/my_fastq_filtered_Q_subsampled/$i.fastq.gz ] ; then 
					log "STARTED : subsampling for $i"
					rasusa -i $raw_files/my_fastq_filtered_Q/$i.fastq.gz \
					-n $subsample \
					-o $raw_files/my_fastq_filtered_Q_subsampled/$i.fastq.gz \
					-O g

					log "FINISHED : subsampling for $i"
					else
					log "ALREADY FINISHED : subsampling for $i"
				fi
			done

			else
			cp $raw_files/my_fastq_filtered_Q/$i.fastq.gz $raw_files/my_fastq_filtered_Q_subsampled/$i.fastq.gz
		fi

###############################################################################
## 03 fastq to fasta
		mkdir $raw_files/my_fastq_filtered_Q_subsampled_fasta > /dev/null 2>&1
		for i in $(cat $sublist); do
			if [ ! -f $raw_files/my_fastq_filtered_Q_subsampled_fasta/$i.fasta ] ; then 
				log "STARTED : fastq to fasta for $i"

				python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastq2fasta.py \
				-i $raw_files/my_fastq_filtered_Q_subsampled/$i.fastq.gz \
				-o $raw_files/my_fastq_filtered_Q_subsampled_fasta/$i.fasta

				sed -i 's/ .*//g' $raw_files/my_fastq_filtered_Q_subsampled_fasta/$i.fasta
				sed -i 's/\t.*//g' $raw_files/my_fastq_filtered_Q_subsampled_fasta/$i.fasta
				
				log "FINISHED : fastq to fasta for $i"
				else
				log "ALREADY FINISHED : fastq to fasta for $i"
			fi
		done

###############################################################################
## 04 split fasta of every barcode to single file 

		mkdir $raw_files/my_fastq_filtered_Q_subsampled_fasta_individual > /dev/null 2>&1
		for i in $(cat $sublist); do 
			if [ ! -d $raw_files/my_fastq_filtered_Q_subsampled_fasta_individual/$i ] ; then 
				log "STARTED : spliting fasta to individual reads for $i"

				mkdir $raw_files/my_fastq_filtered_Q_subsampled_fasta_individual/$i > /dev/null 2>&1

				bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
				-i $raw_files/my_fastq_filtered_Q_subsampled_fasta/$i.fasta \
				-o $raw_files/my_fastq_filtered_Q_subsampled_fasta_individual/$i/

				log "FINISHED : spliting fasta to individual reads for $i"
				else
				log "ALREADY FINISHED : spliting fasta to individual reads for $i"
			fi 
		done

############################################################################### 
## 05 k-mer count by JellyFish

		for i in $( cat $sublist ); do 
			mkdir -p $raw_files/jelly_fish/$i > /dev/null 2>&1
			log "checking k-mer count by JellyFish for $i"
			for sequence in $(ls $raw_files/my_fastq_filtered_Q_subsampled_fasta_individual/$i/ ); do 
				if [ ! -f $raw_files/jelly_fish/$i/$sequence.jf.dump ] ; then 
					log "STARTED : k-mer count by JellyFish for $i : $sequence "

					## -s 1M : using a hash with 1 million elements
					## -m 4 : k-mer size 4
					/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish \
					count -m 4 -s 1M -t $SLURM_CPUS_PER_TASK \
					-o $raw_files/jelly_fish/$i/$sequence.jf \
					$raw_files/my_fastq_filtered_Q_subsampled_fasta_individual/$i/$sequence 

					/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish dump \
					-c $raw_files/jelly_fish/$i/$sequence.jf \
					> $raw_files/jelly_fish/$i/$sequence.jf.dump

					log "FINISHED : k-mer count by JellyFish for $i : $sequence "
				fi
			done 
		done 

###############################################################################
## 06 matrix from kmer counts + tsne plot stat
	## $raw_files/jelly_fish_matrix/$i/matrix.tsv take long time 

	mkdir $raw_files/jelly_fish_matrix > /dev/null 2>&1
	source /home/groups/VEO/tools/biopython/myenv/bin/activate
	for i in $( cat $sublist ); do 
		if [ ! -f $raw_files/jelly_fish_matrix/$i/matrix.tsv ] ; then 
			mkdir $raw_files/jelly_fish_matrix/$i > /dev/null 2>&1

			log "STARTED: creating matrix from kmer counts for $i"
			python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_merge_data_by_dask.faster.py \
			-i $raw_files/jelly_fish/$i \
			-o $raw_files/jelly_fish_matrix/$i/matrix.tsv

			log "STARTED: creating tSNE plot for $i"
			## output is $wd/out/$i/inlier.tsv
			python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_create_a_tsne_plot.py \
			-i $raw_files/jelly_fish_matrix/$i/matrix.tsv \
			-o $raw_files/jelly_fish_matrix/$i

		fi
	done 
	deactivate

###############################################################################
## 07 write $wd/out/$i/inlier.tsv.read_ids
	mkdir $raw_files/jelly_fish_matrix_filtered > /dev/null 2>&1
	source /home/groups/VEO/tools/biopython/myenv/bin/activate

	for i in $( cat $sublist ); do
		if [ ! -f $raw_files/jelly_fish_matrix_filtered/$i.fastq.gz ] ; then 
			log "STARTED: writing inlier reads for $i"

			awk '{print $1}' $raw_files/jelly_fish_matrix/$i/inlier.tsv | sed 's/@//g' > $raw_files/jelly_fish_matrix/$i/inlier.tsv.read_ids

			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/extract_reads_from_fastq.py \
			-i $raw_files/my_fastq_filtered_Q_subsampled/$i.fastq.gz \
			-o $raw_files/jelly_fish_matrix_filtered/$i.fastq.gz \
			-l $raw_files/jelly_fish_matrix/$i/inlier.tsv.read_ids
		fi 
	done
	deactivate

###############################################################################
## 08 long reads to short reads

	mkdir $raw_files/jelly_fish_matrix_filtered_"$final_read_length" > /dev/null 2>&1
	for i in $(cat $sublist ); do
		if [ ! -f $raw_files/jelly_fish_matrix_filtered_"$final_read_length"/$i.fastq.gz ] ; then 
			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/long_reads_to_short_reads.py \
			-i $raw_files/jelly_fish_matrix_filtered/$i.fastq.gz \
			-o $raw_files/jelly_fish_matrix_filtered_"$final_read_length"/$i.fastq.gz \
			-l $final_read_length
		fi 
	done
###############################################################################