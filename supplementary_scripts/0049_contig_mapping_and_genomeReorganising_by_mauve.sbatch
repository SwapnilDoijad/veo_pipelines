#!/bin/bash
#SBATCH --job-name=0049_contig_mapping_and_genomeReorganising_by_mauve
#SBATCH --partition=gpu-veo,standard,long,gpu,gpu-test,short
#SBATCH --output results/0049_contig_mapping_and_genomeReorganising_by_mauve/tmp/slurm/%j.out
#SBATCH --error results/0049_contig_mapping_and_genomeReorganising_by_mauve/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=10
###############################################################################
## step-00: preparation
    pipeline=0049_contig_mapping_and_genomeReorganising_by_mauve
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    choise=$(grep -w "my_choise" $parameters | awk -F'\t' '{print $2}')
    fasta_path=$(grep -w "my_fasta_path" $parameters | awk -F'\t' '{print $2}')
############################################################################### 
    log "STARTED : $pipeline for $sublist"
###############################################################################
## step-02: copy fasta files and run mauve

    if [ $choise == "ordering" ]; then
        while IFS=$'\t' read -r ref_fasta query_fasta; do
            log "running mauve for $ref_fasta and $query_fasta"
            WorDir=$(echo $PWD)
            query_fasta_id=$(basename $query_fasta .fasta)
            cd /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13
            
            java -Xmx16000m -cp Mauve.jar \
            org.gel.mauve.contigs.ContigOrderer \
            -output $query_fasta_id \
            -ref $ref_fasta \
            -draft $query_fasta \
            & my_pid=$!
            get_resource_stat $my_pid $wd/tmp/resource_log/$query_fasta_id.ordering.tsv 

            cd $WorDir

            final_alignment=$(ls /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id/ | sort -r | head -1)
            mv /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id/$final_alignment $raw_files/$query_fasta_id
            cp $raw_files/$query_fasta_id/$query_fasta_id.fasta $wd/all_fasta/$query_fasta_id.aligned.fasta

            if [ -d /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id ]; then
                # else mauve_snapshot_2015-02-13 get deleted
                (rm -rf /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/$query_fasta_id) > /dev/null 2>&1
            fi

        done < $sublist

        elif [ $choise == "viewing" ]; then
            log "running mauve for viewing alignment for all fasta files in $fasta_path"

            /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/linux-x64/progressiveMauve \
            --output="$raw_files/viewing.xmfa" \
            "$fasta_path"/*.fasta \
            & my_pid=$!
            get_resource_stat $my_pid $wd/tmp/resource_log/viewing.tsv 
    else
        log "ERROR: Invalid choice for 'my_choise' in parameters file. Please use 'ordering' or 'alignment'."
        exit 1
    fi
    
############################################################################### 
	log "FINISHED : $pipeline for $sublist" && clean
###############################################################################
## example mauve just command: 
    # /home/groups/VEO/tools/mauve/mauve_snapshot_2015-02-13/linux-x64/mauveAligner \
    # --output my_alignment.xmfa \
    # /vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results/0492_contig_mapping_by_ragtag/all_fasta_plasmid_esp/plsmd3/*.fasta

