#!/bin/bash
#SBATCH --job-name 0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
#SBATCH --partition=interactive
#SBATCH --output results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.out
#SBATCH --error results/0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=your_email@example.com
###############################################################################
## header 
	pipeline=0401_genome_assembly_for_phage_from_nanopore_reads_preprocessing_by_jellyfish
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline -----------------------"
	sublist=results/$pipeline/tmp/lists/ABC
	fastq_path=$( grep my_fastq $parameters | awk '{print $2}' )
###############################################################################
## 01 filter fastq for quality and length (min + max)

	mkdir data/my_fastq_filtered_Q10 > /dev/null 2>&1

	source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate chopper_v0.5.0 

	for i in $( cat $sublist ); do 
		if [ ! -f data/my_fastq_filtered_Q10/$i.fastq.gz ] ; then
			log  "STARTED : filtering for $i"

			zcat $fastq_path/$i.fastq.gz \
			| chopper -q 10  --threads $SLURM_CPUS_PER_TASK --minlength 2000 --maxlength 75000 \
			| gzip > data/my_fastq_filtered_Q10/$i.fastq.gz

			original_fastq_count=$( count_reads_from_fastq $fastq_path/$i.fastq.gz )
			filtered_fastq_count=$( count_reads_from_fastq data/my_fastq_filtered_Q10/$i.fastq.gz )
			echo "$i $original_fastq_count $filtered_fastq_count" | tee -a  data/fastq_count_before_after_filter.tsv

			log  "FINISHED : filtering for $i"
			else 
			log "ALREADY FINISHED : filtering for $i"
		fi
	done

	conda deactivate

###############################################################################
## 02 fastq to fasta
	mkdir data/my_fastq_filtered_Q10_fasta > /dev/null 2>&1
	for i in $(cat $sublist); do
		if [ ! -f data/my_fastq_filtered_Q10_fasta/$i.fasta ] ; then 
			log "STARTED : fastq to fasta for $i"

			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastq2fasta.py \
			-i $fastq_path/$i.fastq.gz \
			-o data/my_fastq_filtered_Q10_fasta/$i.fasta

			sed -i 's/ .*//g' data/my_fastq_filtered_Q10_fasta/$i.fasta
			sed -i 's/\t.*//g' data/my_fastq_filtered_Q10_fasta/$i.fasta
			
			log "FINISHED : fastq to fasta for $i"
			else
			log "ALREADY FINISHED : fastq to fasta for $i"
		fi
	done

###############################################################################
## 03 split fasta of every barcode to single file 
	mkdir data/my_fastq_filtered_Q10_fasta_individual > /dev/null 2>&1
	for i in $(cat $sublist); do 
		if [ ! -d data/my_fastq_filtered_Q10_fasta_individual/$i ] ; then 
			log "STARTED : spliting fasta to individual reads for $i"

			mkdir data/my_fastq_filtered_Q10_fasta_individual/$i > /dev/null 2>&1

			bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_multifasta.sh \
			-i data/my_fastq_filtered_Q10_fasta/$i.fasta \
			-o data/my_fastq_filtered_Q10_fasta_individual/$i/

			log "FINISHED : spliting fasta to individual reads for $i"
			else
			log "ALREADY FINISHED : spliting fasta to individual reads for $i"
		fi 
	done
############################################################################### 
## 04 k-mer count by JellyFish
	for i in $( cat $sublist ); do 
		mkdir -p $raw_files/$i > /dev/null 2>&1
		log "checking k-mer count by JellyFish for $i"
		for sequence in $(ls data/my_fastq_filtered_Q10_fasta_individual/$i/ ); do 
			if [ ! -f $raw_files/$i/$sequence.jf.dump ] ; then 
				log "STARTED : k-mer count by JellyFish for $i : $sequence "

				## -s 1M : using a hash with 1 million elements
				## -m 4 : k-mer size 4
				/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish \
				count -m 4 -s 1M -t $SLURM_CPUS_PER_TASK \
				-o $raw_files/$i/$sequence.jf \
				data/my_fastq_filtered_Q10_fasta_individual/$i/$sequence 

				/home/groups/VEO/tools/jellyfish/v2.3.0/jellyfish dump \
				-c $raw_files/$i/$sequence.jf \
				> $raw_files/$i/$sequence.jf.dump

				log "FINISHED : k-mer count by JellyFish for $i : $sequence "
			fi
		done 
	done 

###############################################################################
## 05 matrix from kmer counts + tsne plot stat
	## $raw_files/$i/matrix.tsv take long time 
	source /home/groups/VEO/tools/biopython/myenv/bin/activate
	for i in $( cat $sublist ); do 
		if [ ! -f $raw_files/$i/matrix.tsv ] ; then 
			mkdir -p $wd/out/$i > /dev/null 2>&1

			log "STARTED: creating matrix from kmer counts for $i"

			python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_merge_data_by_dask.py \
			-i $raw_files/$i/ \
			-o $raw_files/$i/matrix.tsv

		fi
	done 

	for i in $( cat $sublist ); do 
		if [ ! -f $wd/out/$i/inliers_outliers_plot.png ] ; then 
			log "STARTED: creating tSNE plot for $i"

			## output is $wd/out/$i/inlier.tsv
			python /home/groups/VEO/scripts_for_users/supplementary_scripts/0401_create_a_tsne_plot.py \
			-i $raw_files/$i/matrix.tsv \
			-o $wd/out/$i

		fi
	done 
	deactivate

###############################################################################
## 06 write $wd/out/$i/inlier.tsv.read_ids
	mkdir data/my_fastq_filtered_Q10_based_on_kmers > /dev/null 2>&1
	source /home/groups/VEO/tools/biopython/myenv/bin/activate

	for i in $( cat $sublist ); do
		if [ ! -f data/my_fastq_filtered_Q10_based_on_kmers/$i.fastq.gz ] ; then 
			log "STARTED: writing inlier reads for $i"

			awk '{print $1}' $wd/out/$i/inlier.tsv | sed 's/@//g' > $wd/out/$i/inlier.tsv.read_ids

			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/extract_reads_from_fastq.py \
			-i $fastq_path/$i.fastq.gz \
			-o data/my_fastq_filtered_Q10_based_on_kmers/$i.fastq.gz \
			-l $wd/out/$i/inlier.tsv.read_ids
		fi 
	done
	deactivate

###############################################################################
## 07 long reads to short reads

	mkdir data/my_fastq_filtered_Q10_based_on_kmers_5K > /dev/null 2>&1
	for i in $(cat $sublist ); do
		if [ ! -f data/my_fastq_filtered_Q10_based_on_kmers_5K/$i.fastq.gz ] ; then 
			python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/long_reads_to_short_reads.py \
			-i data/my_fastq_filtered_Q10_based_on_kmers/$i.fastq.gz \
			-o data/my_fastq_filtered_Q10_based_on_kmers_5K/$i.fastq.gz \
			-l 5000
		fi 
	done
###############################################################################