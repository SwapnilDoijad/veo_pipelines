#!/bin/bash
#SBATCH --job-name 0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta
#SBATCH --partition=standard,long,interactive
#SBATCH --output results/0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta/tmp/slurm/%j.out
#SBATCH --error  results/0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0411_genome_assembly_of_phage_from_nanopore_reads_by_Shasta
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	
    fastq_path=$( grep my_fastq_dir $parameters | awk '{print $2}' )
    sublist=$wd/tmp/lists/ABC
###############################################################################
## step-01: runnig Shasta tool 
	for i in $(cat $sublist); do

        if [ ! -f $wd/raw_files/$i/Assembly.fasta ] ; then 
            log "STARTED : $pipeline : $i"
            gzip -dk $fastq_path/$i.fastq.gz
            
            /home/groups/VEO/tools/shasta/v0.11.1/shasta-Linux-0.11.1 \
            --input $fastq_path/$i.fastq \
            --config /home/groups/VEO/tools/shasta/v0.11.1/Nanopore-May2020.modified_for_phage_by_Swapnil \
            --assemblyDirectory $wd/raw_files/$i \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$id.shasta.tsv 

            rm $fastq_path/$i.fastq
            log "FINISHED : $pipeline : $i"
        fi

        if ! grep -qw "$i" $raw_files/$i/assembly_stat.txt ; then
            python3 $suppl_scripts/utilities/get_fasta_length.py \
            -i $raw_files/$i/Assembly.fasta \
            | sed "s/^/$i\t/g" >> $raw_files/$i/assembly_stat.txt
        fi


        contigs=$(grep -c ">" $raw_files/$i/Assembly.fasta)
        length=$(grep -v ">" $raw_files/$i/Assembly.fasta | tr -d '\n' | wc -c )
        echo -e "$i\t$contigs\t$length" | tee -a $wd/summary.tsv

	done 

###############################################################################


