#!/bin/bash
#SBATCH --job-name 0447_genome_assembly_for_phage_from_nanopore_reads_by_raven
#SBATCH --partition=interactive
#SBATCH --output results/0447_genome_assembly_for_phage_from_nanopore_reads_by_raven/tmp/slurm/%j.out
#SBATCH --error  results/0447_genome_assembly_for_phage_from_nanopore_reads_by_raven/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0447_genome_assembly_for_phage_from_nanopore_reads_by_raven
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
###############################################################################
    log "STARTED SBATCH : $pipeline : $sublist"
###############################################################################
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
    conda activate raven_v1.8.3

        for i in $(cat $sublist); do
            log "STARTED : running raven-assembler for $i"
            mkdir $raw_files/$i

            raven -t $SLURM_CPUS_PER_TASK \
             $data_directory_fastq_path/$i.fastq.gz \
            > $raw_files/$i/$i.fasta

            log "FINISHED: The raven-assembler for $i is finished"
        done
        
###############################################################################
    log "FINISHED SBATCH : $pipeline : $sublist"
###############################################################################


# ###############################################################################
# ## step-02: wait untill assembly is finished
# 	if [ ! -f results/0053_metagenome_assembly_by_raven/tmp/get_the_stat_of_fasta_finished.txt ] ; then 
# 		counter=0
# 		max_attempts=180  # 60 attempts * 1 minute = 1 hour

# 		cat $list > results/0053_metagenome_assembly_by_raven/tmp/tmp.list

# 		while [ $counter -lt $max_attempts ]  && [ -s results/0053_metagenome_assembly_by_raven/tmp/tmp.list ] ; do
# 			for i in $(cat results/0053_metagenome_assembly_by_raven/tmp/tmp.list); do
# 				if [ -f "$raw_files/$i/$i.fasta" ]; then
# 					sed -i "/$i/d" results/0053_metagenome_assembly_by_raven/tmp/tmp.list
# 					echo "raven assembly $i finished, no more waiting"
# 					break
# 					else
# 					echo "raven assembly $i not finished in $counter minutes"
# 					echo "waiting for 1 more minute and will check again (will wait maximum $max_attempts minutes)"
# 					sleep 60
# 					counter=$((counter + 1))
# 				fi
# 			done
# 		done

# 		if [ $counter -eq $max_attempts ]; then
# 			echo "File not found after 3 hour. Exiting..."
# 		fi

# 		rm results/0053_metagenome_assembly_by_raven/tmp/tmp.list
# 		sleep 60 ## needed for the files to be writen, it takes time for the raven 
# 		echo "raven assembly finished" > results/0053_metagenome_assembly_by_raven/tmp/raven_assembly.finished
# 	fi 

# ###############################################################################
# ## step-03: run metaquast
# 	echo "running metaquast "
#     for i in $(cat $list); do  
# 		if [ -f $raw_files/$i/$i.fasta ] ; then 
# 			if [ ! -d $raw_files/$i/metaquast/fasta ] ; then 
# 				echo "metaquast for $i: running"
# 				mkdir -p $raw_files/$i/metaquast/fasta
# 				cp $raw_files/$i/$i.fasta \
# 				$raw_files/$i/metaquast/fasta/

# 				cp $raw_files/$i/$i.fasta \
# 				results/0053_metagenome_assembly_by_raven/all_fasta/$i.fasta

# 				( python3 /home/groups/VEO/tools/quast/v5.2.0/metaquast.py --silent --circos \
# 				-o $raw_files/$i/metaquast/ \
# 				$raw_files/$i/metaquast/fasta/*  ) > /dev/null 2>&1
# 				else
# 				echo "metaquast for $i: already finished" 
# 			fi 
# 		fi
#     done 

# 	for i in $(cat $list); do  
# 		if [ -f $raw_files/$i/$i.fasta ] ; then 
# 			awk -F'\t' '{print $2}' $raw_files/$i/metaquast/report.tsv | sed "s/assembly/$i/g" \
# 			> results/0053_metagenome_assembly_by_raven/tmp/$i.metaquast.txt 
# 			else
# 			echo $i > results/0053_metagenome_assembly_by_raven/tmp/$i.metaquast.txt 
# 			for i in {1..22}; do echo "na" >> results/0053_metagenome_assembly_by_raven/tmp/$i.metaquast.txt ; done
# 		fi 
# 	done 
# 	sleep 10
# 	paste /home/groups/VEO/tools/quast/v5.2.0/quast_out.txt results/0053_metagenome_assembly_by_raven/tmp/*.metaquast.txt \
# 	> results/0053_metagenome_assembly_by_raven/summary.tsv
# ###############################################################################
# ## step-04: split mulitfasta to single fasta
# 	( mkdir data/all_fasta_splitted )> /dev/null 2>&1
# 	for i in $(cat list.my_fasta.txt ); do
# 		echo "STARTED: splitting and renaming $i"
# 		( rm -rf results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1 )> /dev/null 2>&1
# 		echo $i
# 		/home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_fasta.pl \
# 		--input_file=results/0052_metagenome_assembly_by_fly/all_fasta/$i.fasta \
# 		--output_dir=results/0052_metagenome_assembly_by_fly/raw_files/$i \
# 		--output_subdir_prefix=all_fasta_splitted_ \
# 		--output_subdir_size 10000 
# 		for i2 in $( ls results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/ ); do 
# 			mv results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/$i2 \
# 			results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/"$i"_"$i2"
# 			sed -i "s/>/>"$i"_/g" results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/"$i"_"$i2"
# 		done 
# 		cp results/0052_metagenome_assembly_by_fly/raw_files/$i/all_fasta_splitted_1/*.fasta \
# 		data/all_fasta_splitted/
# 	done  
# ###############################################################################
# ## step-05: send report by email (with attachment)

#     echo "sending email"
#     user=$(whoami)
#     user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

#     source /home/groups/VEO/tools/email/myenv/bin/activate

#     python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0053_metagenome_assembly_by_raven.py -e $user_email

#     deactivate
###############################################################################
    	echo "FINISHED : $pipeline ---------------------------------"
###############################################################################