#!/bin/bash
#SBATCH --job-name 0061_identification_by_gtdbtk
#SBATCH --partition=gpu,gpu-veo,standard,long
#SBATCH --output results/0061_identification_by_gtdbtk/tmp/slurm/%j.out.0061_identification_by_gtdbtk.txt
#SBATCH --error results/0061_identification_by_gtdbtk/tmp/slurm/%j.err.0061_identification_by_gtdbtk.txt
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
###############################################################################
## header
    pipeline=0061_identification_by_gtdbtk
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file_dir=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
    # sublist=$wd/tmp/lists/ABC
    sublist=list.$pipeline.tmp
###############################################################################
    log "STARTED: $pipeline : $list"
###############################################################################
## notes
    ## 2025-02-16 05:00:55 conda env config vars set GTDBTK_DATA_PATH="/veodata/03/databases/gtdbtk/r214/release214";
    ## for more conda env config see https://ecogenomics.github.io/GTDBTk/installing/bioconda.html (conda env config vars set GTDBTK_DATA_PATH="/path/to/unarchived/gtdbtk/data";)
    ## https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#setting-environment-variables

    export GTDBTK_DATA_PATH=/veodata/03/databases/gtdbtk/release226/

    # source /home/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    # conda activate gtdbtk_v2.1.1
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate gtdbtk_v2.4.1

    log "RUNNING: $pipeline"

    gtdbtk classify_wf \
    --cpus $SLURM_CPUS_PER_TASK \
    --batchfile $sublist \
    --out_dir $raw_files/$sublist \
    --extension fasta \
    --mash_db /veodata/03/databases/gtdbtk/release226/mash_file.msh \
    & my_pid=$! 
    get_resource_stat $my_pid $wd/tmp/resource_log/$sublist.gtdbtk.tsv 

    log "FINISHED: $pipeline"

###############################################################################
## footer
    log "FINISHED: $pipeline : $list"
###############################################################################