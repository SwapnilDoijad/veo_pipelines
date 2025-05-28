#!/bin/bash
#SBATCH --job-name=0641_phage_detection_by_vibrant
#SBATCH --partition=standard
#SBATCH --output=results/0641_phage_detection_by_vibrant/tmp/slurm/%j.out
#SBATCH --error=results/0641_phage_detection_by_vibrant/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0641_phage_detection_by_vibrant
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_path=$(grep "my_fasta_path" $parameters | awk '{print $2}')
	sublist=$wd/tmp/lists/ABC

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate vibrant_v1.2.0
###############################################################################
log "STARTED: $sublist -----------------------------"
###############################################################################

    for i in $(cat $sublist ); do
        log "STARTED : $pipeline : $i"
        mkdir -p $raw_files/$i

        VIBRANT_run.py \
        -i $fasta_path/$i.fasta \
        -t $SLURM_CPUS_PER_TASK \
        -folder $raw_files/$i \
        -d /veodata/03/databases/vibrant/v20230318/databases/ \
        -m /veodata/03/databases/vibrant/v20230318/files/ \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$i.vibrant.tsv 

        log "ENDED : $pipeline : $i"
    done
###############################################################################
log "FINISHED: $sublist -----------------------------"
###############################################################################