#!/bin/bash
#SBATCH --job-name 0171_comparative_genomics_core_pan_by_panaroo
#SBATCH --partition=short
#SBATCH --output results/0171_comparative_genomics_core_pan_by_panaroo/tmp/slurm/%j.out.0171_comparative_genomics_core_pan_by_panaroo
#SBATCH --error results/0171_comparative_genomics_core_pan_by_panaroo/tmp/slurm/%j.err.0171_comparative_genomics_core_pan_by_panaroo
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################

    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    log "STARTED: 0171_comparative_genomics_core_pan_by_panaroo pipeline"
    mkdir -p "results/0171_comparative_genomics_core_pan_by_panaroo/raw_files"
    parameter_file="tmp/parameters/cp0010_phage_contigs_to_comparative.parameters.yaml"
    yq=/home/groups/VEO/tools/yq/v4.42.1/yq

# Activate conda environment
    log "Activating conda environment"
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate panaroo_v1.2.10

# Read parameters from parameter file
    sequence_identity_threshold=$($yq eval '.pipelines[] | select(.name == "0171_phage_contigs_to_comparative") | .parameters.sequence_identity_threshold.value' $parameter_file )
    length_difference_cutoff=$($yq eval '.pipelines[] | select(.name == "0171_phage_contigs_to_comparative") | .parameters.length_difference_cutoff.value' $parameter_file )
    alignment_type=$($yq eval '.pipelines[] | select(.name == "0171_phage_contigs_to_comparative") | .parameters.alignment_type.value' $parameter_file )

# Run panaroo
    log "Running panaroo pipeline"
    panaroo \
        -i results/0171_comparative_genomics_core_pan_by_panaroo/tmp/gff/*.gff \
        -o "results/0171_comparative_genomics_core_pan_by_panaroo/raw_files" \
        -t 80 \
        -c "$sequence_identity_threshold" \
        --len_dif_percent "$length_difference_cutoff" \
        --quiet \
        --clean-mode strict \
        --merge_paralogs \
        -a "$alignment_type"

    log "ENDED: 0171_comparative_genomics_core_pan_by_panaroo pipeline"


panaroo -i results/0081_annotation_bacteria_by_prokka/all_gff/*.gff -o results/0171_comparative_genomics_core_pan_by_panaroo/raw_files -t 80 -c 0.70 --len_dif_percent 0.70 --quiet  --clean-mode strict  --merge_paralogs -a core 