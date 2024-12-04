#!/bin/bash
#SBATCH --job-name gerbil
#SBATCH --partition=fat
#SBATCH --output  results/0881_kmer_counting/tmp/slurm/out.%j.slurmenv.txt
#SBATCH --error   results/0881_kmer_counting/tmp/slurm/err.%j.slurmenv.txt
#-- Command section ------------------------

list=results/0881_kmer_counting/tmp/lists/tmp_list
for fastq_path in $(cat $list); do 
	echo "gerbil for $fastq_path started"

	my_path=$(grep fastq.gz result_summary.read_me.txt | awk '{print $NF}')
	fastq_id=$(echo $fastq_path | awk -F'/' '{ print $NF}' | awk -F'.' '{print $1}' )
	echo "$my_path/$fastq_id.fastq" > results/0881_kmer_counting/tmp/lists/$fastq_id.txt

	gunzip -k $fastq_path 
	( mkdir -p results/0881_kmer_counting/$fastq_id ) > /dev/null 2>&1

	/home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil \
	-k 9 -t 10 -o fasta -x h \
	results/0881_kmer_counting/tmp/lists/$fastq_id.txt \
	results/0881_kmer_counting/$fastq_id/tmp \
	results/0881_kmer_counting/$fastq_id/out.txt

	echo "gerbil for $fastq_path finished"
done 