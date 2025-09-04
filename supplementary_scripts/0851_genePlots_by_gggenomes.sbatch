#!/bin/bash
#SBATCH --job-name=0851_genePlots_by_gggenomes
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu-test,gpu
#SBATCH --output=results/0851_genePlots_by_gggenomes/tmp/slurm/%j.out
#SBATCH --error=results/0851_genePlots_by_gggenomes/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0851_genePlots_by_gggenomes
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    data_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )

	mash_tool_path=/home/groups/VEO/tools/mash/v2.3
###############################################################################
	log "STARTED :SBATCH : $pipeline -----------------------------"
###############################################################################
## step-1 : converting file format
	source /home/groups/VEO/tools/biopython/myenv/bin/activate

	for i in $(ls $data_directory); do 
		python3 $suppl_scripts/utilities/gff2fasta.py \
		--gff $raw_files/$i/$i.gff \
		--output $wd/fasta/$i.fasta

		python $suppl_scripts/$pipeline.extract_cds_for_blast.py \
		-i $data_directory/$i.gff \
		-o $wd/cds/$i.cds.fasta 
	done 

###############################################################################
## step-2: generating mash sketches
	for i in $(cat $list ); do
		$mash_tool_path/mash sketch \
		-s 1000 -p $SLURM_CPUS_PER_TASK \
		-o $raw_files/msh/$i.mash_sketch.msh \
		$fasta_file_path/$i.fasta 
	done

	$mash_tool_path/mash dist \
	-p $SLURM_CPUS_PER_TASK \
	$raw_files/msh/$i.mash_sketch.msh \
	$raw_files/msh/$i2.mash_sketch.msh \
	> $raw_files/distance/$i.$i2.dist.tsv

	for i in $(cat $list ); do
        for i2 in $(cat $sublist ); do
            log "RUNNING: calculating SGC_ANI $i"

            awk '{print $5}' $raw_files/distance/$i.$i2.dist.tsv \
            | awk -F'/' '{print $1*100/1000 }' | tr ' ' '\n' \
            > $raw_files/SGC_ANI/tmp/$i.$i2.SGC.txt

            awk '{print (1-$3)*100}' $raw_files/distance/$i.$i2.dist.tsv \
            | tr ' ' '\n' > $raw_files/SGC_ANI/tmp/$i.$i2.ANI.txt

            paste $raw_files/SGC_ANI/tmp/$i.$i2.SGC.txt \
            $raw_files/SGC_ANI/tmp/$i.$i2.ANI.txt \
            > $raw_files/SGC_ANI/tmp/$i.$i2.SGC_ANI.txt

            awk '{print $1*$2/100}' $raw_files/SGC_ANI/tmp/$i.$i2.SGC_ANI.txt \
            > $raw_files/SGC_ANI/tmp/$i.$i2.txt

            cat $raw_files/SGC_ANI/tmp/$i.$i2.txt \
            >> $raw_files/SGC_ANI/tmp/$i2.txt

            cat $raw_files/SGC_ANI/tmp/$i.$i2.ANI.txt \
            >> $raw_files/SGC_ANI/tmp/$i2.ANI.txt
        done 
    done

	# mapfile -t ids < ${sp}/list.phylo_seq.txt
	# for ((i=0; i<${#ids[@]}-1; i++)); do
	# 	query=${ids[i]}
	# 	subject=${ids[i+1]}

	# 	echo "Running BLAST: $query vs $subject"

	# 	/home/groups/VEO/tools/blast/v2.14.0/bin/makeblastdb \
	# 	-in $wd/cds/$i.cds.fasta \
	# 	-dbtype nucl \
	# 	-out $wd/blast/$i

	# 	/home/groups/VEO/tools/blast/v2.14.0/bin/blastn \
	# 	-query $wd/cds/$i.cds.fasta \
	# 	-db $wd/blast/"${subject}_db" \
	# 	-out $wd/blast/"${query}_vs_${subject}.blast" \
	# 	-outfmt 6 -max_target_seqs 1 -evalue 1e-5 -num_threads 4
	# done

###############################################################################
	log "ENDED :SBATCH : $pipeline -----------------------------"
############################################################################### 