#!/bin/bash
#SBATCH --job-name=0049_contig_mapping_and_genomeReorganising_by_mauve
#SBATCH --partition=gpu-veo,standard,long,gpu,gpu-test
#SBATCH --output results/0049_contig_mapping_and_genomeReorganising_by_mauve/tmp/slurm/%j.out
#SBATCH --error results/0049_contig_mapping_and_genomeReorganising_by_mauve/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0049_contig_mapping_and_genomeReorganising_by_mauve
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC

############################################################################### 
    log "STARTED : $pipeline for $sublist"
###############################################################################
## step-02: copy fasta files and run mauve

    while IFS=$'\t' read -r ref_fasta query_fasta; do
        log "running mauve for $ref_fasta and $query_fasta"
        WorDir=$(echo $PWD)
        query_fasta_id=$(basename $query_fasta .fasta)
        cd /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13
        
        java -Xmx16000m -cp Mauve.jar \
        org.gel.mauve.contigs.ContigOrderer \
        -output $query_fasta_id \
        -ref $ref_fasta \
        -draft $query_fasta
 
        cd $WorDir

        final_alignment=$(ls /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id/ | sort -r | head -1)
        mv /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id/$final_alignment $raw_files/$query_fasta_id
        cp $raw_files/$query_fasta_id/$query_fasta_id.fasta $wd/all_fasta/$query_fasta_id.aligned.fasta

        if [ -d /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id ]; then
            # else mauve_snapshot_2015-02-13 get deleted
            (rm -rf /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id) > /dev/null 2>&1
        fi


    done < $sublist


############################################################################### 
	log "FINISHED : $pipeline for $sublist" && clean
############################################################################### 