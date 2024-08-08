( mkdir -p results/0881_kmer_counting/tmp/slurm ) > /dev/null 2>&1
( mkdir -p results/0881_kmer_counting/tmp/sbatch ) > /dev/null 2>&1
( mkdir -p results/0881_kmer_counting/tmp/lists ) > /dev/null 2>&1

fastq_path=$( grep fastq result_summary.read_me.txt | awk '{print $NF}')
find $fastq_path -maxdepth 1 -type f > list.fastq_with_path.txt 
total_ids=$( nl list.fastq_with_path.txt | wc -l )
echo "$total_ids ids found in the list.fastq_with_path.txt file"

if [ $total_ids -gt 1 ] ; then 
	split -a 3 --numeric-suffixes -l 1  list.fastq_with_path.txt results/0881_kmer_counting/tmp/lists/list.fastq_with_path.txt.out 
fi

( rm /home/xa73pav/projects/p_gerbil_demo/results/0881_kmer_counting/tmp/lists/list.fastq_with_path.txt.out ) > /dev/null 2>&1
ls results/0881_kmer_counting/tmp/lists/list.fastq_with_path.txt.out* > results/0881_kmer_counting/tmp/lists/list.fastq_with_path.txt.out 

for split_list in $(cat results/0881_kmer_counting/tmp/lists/list.fastq_with_path.txt.out  ); do
	echo "creating sbatch script $split_list"
	split_list_id=$(echo $split_list | awk -F'/' '{ print $NF}' )
	sed 's/tmp_list/'"$split_list_id"'/g' /home/groups/VEO/scripts_for_users/supplementary_scripts/0881_kmer_counting_by_gerbil.sbatch > results/0881_kmer_counting/tmp/sbatch/$split_list_id.sbatch
	sbatch results/0881_kmer_counting/tmp/sbatch/$split_list_id.sbatch
done 