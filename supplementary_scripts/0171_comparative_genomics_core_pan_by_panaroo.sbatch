#!/bin/bash
#SBATCH --job-name 0171_comparative_genomics_core_pan_by_panaroo
#SBATCH --partition=interactive,short
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

###############################################################################
# Run panaroo
    log "STARTED: 0171_comparative_genomics_core_pan_by_panaroo pipeline"

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate panaroo_v1.2.10

    log "Running panaroo pipeline"
    panaroo \
        -i $gff_dir/*.gff3 \
        -o "$raw_files" \
        -t 80 \
        -c "$sequence_identity_threshold" \
        --len_dif_percent "$length_difference_cutoff" \
        --quiet \
        --clean-mode strict \
        --merge_paralogs \
        -a "$alignment_type" \
        --remove-invalid-genes

    log "ENDED: 0171_comparative_genomics_core_pan_by_panaroo pipeline"

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
###############################################################################
    log "SBATCH ENDED : $pipeline ----------------------" && clean
###############################################################################