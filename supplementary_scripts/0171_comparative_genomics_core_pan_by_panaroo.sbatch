#!/bin/bash
#SBATCH --job-name 0171_comparative_genomics_core_pan_by_panaroo
#SBATCH --partition=gpu-veo,gpu,gpu-test,long,standard
#SBATCH --output results/0171_comparative_genomics_core_pan_by_panaroo/tmp/slurm/%j.out.0171_comparative_genomics_core_pan_by_panaroo
#SBATCH --error results/0171_comparative_genomics_core_pan_by_panaroo/tmp/slurm/%j.err.0171_comparative_genomics_core_pan_by_panaroo
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################
    pipeline=0171_comparative_genomics_core_pan_by_panaroo
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    mkdir -p "results/0171_comparative_genomics_core_pan_by_panaroo/raw_files"

    sequence_identity_threshold=$( grep "my_sequence_identity_threshold" $parameters | awk '{print $2}' )
    length_difference_cutoff=$( grep "my_length_difference_cutoff" $parameters | awk '{print $2}' )
    alignment_type=$( grep "my_alignment_type" $parameters | awk '{print $2}' )
    gff_dir=$( grep "my_gff_dir" $parameters | awk '{print $2}' )
    tree=$( grep "my_tree_choice" $parameters | awk '{print $2}' )
###############################################################################
# Run panaroo
    log "STARTED: 0171_comparative_genomics_core_pan_by_panaroo pipeline"

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate panaroo_v1.2.10

    log "Running panaroo pipeline"
    panaroo \
        -i $gff_dir/*.gff \
        -o "$raw_files" \
        -t 80 \
        -c "$sequence_identity_threshold" \
        --len_dif_percent "$length_difference_cutoff" \
        --quiet \
        --clean-mode strict \
        --merge_paralogs \
        -a "$alignment_type" \
        --remove-invalid-genes  \
        & my_pid=$!
        get_resource_stat $my_pid $resource_log/panaroo.tsv 

    log "ENDED: 0171_comparative_genomics_core_pan_by_panaroo pipeline"

    if [ "$tree" = "Yes" ]; then
        log "FastTree: Building tree based on core gene alignment"

        /home/groups/VEO/tools/fastTreeMP/v2.2.0/FastTree \
        -nt -gtr \
        $raw_files/core_gene_alignment.aln \
        > $raw_files/core_gene_alignment.aln.fasttree

        log "iqtree: Building tree based on core gene alignment"
        ## for bootstrapping use iq-tree
        /home/groups/VEO/tools/iqtree/1.6.12/bin/iqtree \
        -s $raw_files/core_gene_alignment.aln \
        -m GTR+G -bb 1000 -alrt 1000 -nt 80 -pre \
        $raw_files/core_gene_alignment.aln.iqtree

        python $suppl_scripts/utilities/export_phylogenomic_tip_labels.py \
        -i $raw_files/core_gene_alignment.aln.iqtree.treefile \
        -o $raw_files/core_gene_alignment.aln.iqtree.treefile.label 
        
    fi


# run the core gene alignment
    # panaroo -i results/0081_annotation_bacteria_by_prokka/all_gff/*.gff \
    # -o results/0171_comparative_genomics_core_pan_by_panaroo/raw_files \
    # -t 80 -c 0.70 --len_dif_percent 0.70 \
    # --quiet  --clean-mode strict  --merge_paralogs -a core 

    # panaroo -i *.gff -o panaroo_output --clean-mode strict --align --core_threshold 0.99

## for scoary in same env
    # scoary \
    # -g raw_files/gene_presence_absence.csv \
    # -t raw_files/traits.csv \
    # -s 4 \
    # --threads 20 \
    # -o scoary_results 

## for closely realted genomes
    #  FastTree -nt -gtr -gamma -spr 4 -mlacc 3 -slow alignment.fasta > tree.nwk

## snippy step
    snp-dists $raw_files/core_gene_alignment.aln \
    > $raw_files/core_gene_alignment.aln.snp-dist

    
###############################################################################
    log "SBATCH ENDED : $pipeline ----------------------" && clean
###############################################################################