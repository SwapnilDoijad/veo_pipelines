#!/bin/bash
#SBATCH --job-name=0222_gene_detection_abr_by_CARD-rgi
#SBATCH --partition=standard,long
#SBATCH --output=results/0222_gene_detection_abr_by_CARD-rgi/tmp/slurm/%j.out
#SBATCH --error=results/0222_gene_detection_abr_by_CARD-rgi/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
#SBATCH --mem=200G
###############################################################################
## step-01: preparation
    pipeline=0222_gene_detection_abr_by_CARD-rgi
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	sublist=results/$pipeline/tmp/lists/ABC
    fasta_directory=$( grep my_fasta_directory $parameters | awk '{print $2}' )
    alignment_tool=$(echo DIAMOND) #{DIAMOND,BLAST}
	echo $raw_files
###############################################################################
## run card
    source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate rgi_v6.0.2

    for i in $(cat $sublist); do
        if [ ! -f $raw_files/$i.txt ]; then
			mkdir -p $raw_files/$i
            log "RUNNIG: ARD-ABR v$card_software_version for $i with $card_database_version database using $alignment_tool alignment_tool"

            rgi main \
			-i $fasta_directory/$i.fasta \
			-o $raw_files/$i/$i \
			-a $alignment_tool \
			-t contig \
			-n $SLURM_CPUS_PER_TASK \
			--clean

			sed -i 's/ /_/g' $raw_files/$i/$i.txt

            #sudo rgi main -i results/08_annotation/raw_files/And1463/And1463.faa -o results/0222_CARD-AR_results/results/$i -a DIAMOND -t protein --clean
            #/home/swapnil/tools/rgi-5.0.0/rgi-5.0.0/
            #rgi main -i results/08_annotation/raw_files/$i/$i.faa -o results/0222_CARD-AR_results/results/$i -a $alignment_tool -t protein --clean
            #rgi main -i results/08_annotation/raw_files/$i/$i.faa -o results/0222_CARD-AR_results/results/$i -a $alignment_tool -t protein --clean #> /dev/null 2>&1
			log "FINISHED: $i"
            else
            log "ALREADY FINISHED: $i"
       fi
    done
###############################################################################