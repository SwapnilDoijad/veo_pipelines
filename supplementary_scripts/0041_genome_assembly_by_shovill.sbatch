#!/bin/bash
#SBATCH --job-name 0041_genome_assembly_by_shovill
#SBATCH --partition=fat
#SBATCH --output results/0041_genome_assembly_by_shovill/tmp/slurm/%j.out
#SBATCH --error results/0041_genome_assembly_by_shovill/tmp/slurm/%j.err
#SBATCH --mem=1000G
#SBATCH --cpus-per-task=10 
###############################################################################
    pipeline=0041_genome_assembly_by_shovill
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -------------------------------------"
    
    sublist=$wd/tmp/lists/ABC

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate shovill_v1.1.0
###############################################################################
## step-01: run shovill assembler

   echo "--------------------------------------------------------------------------------"
    for i in $(cat $sublist) ; do
        if [ ! -d $raw_files/$i ] ; then 
            if [ -f $data_directory_fastq_path/"$i"_*R1*.fastq.gz ] && [ -f $data_directory_fastq_path/"$i"_*R2*.fastq.gz ]; then 
                if [ ! -d $raw_files/$i ] ; then 
                    echo "running: shovill assembly for $i"
                    shovill --trim --outdir $raw_files/$i \
                    --R1  $data_directory_fastq_path/"$i"_*R1*.fastq.gz \
                    --R2  $data_directory_fastq_path/"$i"_*R2*.fastq.gz \
                    --cpus 10 --ram 1000 --opts --isolate \
                    --minlen 200 --mincov 10 --keepfiles
                    echo "finished: shovill assembly for $i" 
                    else
                    echo "fastq not found for $i"
                fi
            fi

        else
        echo $i already finished  
        fi
    done 
    echo "--------------------------------------------------------------------------------"

###############################################################################
## step-02: post-assembly statistics and coverting fasta files
    (mkdir -p $wd/all_fasta ) > /dev/null 2>&1 

	for i in $(cat $sublist); do
		if [ ! -f  $wd/all_fasta/$i.fasta ] && [ -f $raw_files/$i/contigs.fa ] ; then
            (mkdir -p $raw_files/$i/tmp ) > /dev/null 2>&1
			cp $raw_files/$i/contigs.fa  $raw_files/$i/$i.fasta
			number_of_contigs=$(grep -c ">"  $raw_files/$i/$i.fasta)
			grep -F ">"  $raw_files/$i/$i.fasta | awk -F'[= ]' '$3 > 240 && $5 > 20' | sed -e 's/>//g' >  $raw_files/$i/tmp/$i.10-500-filtered-contigs.csv
			perl /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastagrep.pl -f $raw_files/$i/tmp/$i.10-500-filtered-contigs.csv $raw_files/$i/$i.fasta > $raw_files/$i/$i.contigs-filtered.fasta
			number_of_filtered_contigs=$(grep -c ">"  $raw_files/$i/$i.contigs-filtered.fasta)
			length_of_filtered_contigs=$(awk -F '_' '{ sum += $6; n++ } END { if (n > 0) print sum / n; }'  $raw_files/$i/tmp/$i.10-500-filtered-contigs.csv)
			echo $number_of_contigs $number_of_filtered_contigs $length_of_filtered_contigs > $raw_files/$i/tmp/$i.5_filtering_contigs.statistics.tab
			cp $raw_files/$i/$i.contigs-filtered.fasta $wd/all_fasta/$i.fasta
		fi
	done
###############################################################################