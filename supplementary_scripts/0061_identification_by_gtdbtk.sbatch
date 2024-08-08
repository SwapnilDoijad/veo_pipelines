#!/bin/bash
#SBATCH --job-name 0061_identification_by_gtdbtk
#SBATCH --partition=gpu
#SBATCH --output results/0061_identification_by_gtdbtk/tmp/slurm/%j.out.0061_identification_by_gtdbtk.txt
#SBATCH --error results/0061_identification_by_gtdbtk/tmp/slurm/%j.err.0061_identification_by_gtdbtk.txt
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
    start_time=$(date +"%Y%m%d_%H%M%S")
###############################################################################
## notes
    ## the db path changed from default GTDBTK_DATA_PATH = /home/groups/VEO/tools/anaconda3/envs/gtdbtk_v2.1.1/share/gtdbtk-2.1.1/db to
    ## conda env config vars set GTDBTK_DATA_PATH="/work/groups/VEO/databases/gtdbtk/r207_v2"
    ## for more conda env config see https://ecogenomics.github.io/GTDBTk/installing/bioconda.html (conda env config vars set GTDBTK_DATA_PATH="/path/to/unarchived/gtdbtk/data";)
    ## https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#setting-environment-variables

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate gtdbtk_v2.1.1

    sublist=ABC

    echo "0061_identification_by_gtdbtk for $sublist: running"

    gtdbtk classify_wf --cpus $SLURM_CPUS_PER_TASK \
    --batchfile results/0061_identification_by_gtdbtk/tmp/lists/$sublist \
    --out_dir results/0061_identification_by_gtdbtk/results/$sublist --extension fasta

    echo "0061_identification_by_gtdbtk for $sublist: finished"

###############################################################################
## footer
    end_time=$(date +"%Y%m%d_%H%M%S")
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/time_calculations.sh "$start_time" "$end_time"
###############################################################################