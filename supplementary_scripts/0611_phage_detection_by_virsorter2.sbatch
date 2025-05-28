#!/bin/bash
#SBATCH --job-name=0611_phage_detection_by_virsorter2
#SBATCH --partition=standard
#SBATCH --output=results/0611_phage_detection_by_virsorter2/tmp/slurm/%j.out
#SBATCH --error=results/0611_phage_detection_by_virsorter2/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0611_phage_detection_by_virsorter2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_path=$(grep "my_fasta_path" $parameters | awk '{print $2}')
	sublist=$wd/tmp/lists/ABC

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate virsorter2

###############################################################################
log "STARTED: $sublist -----------------------------"
###############################################################################

    for i in $(cat $sublist ); do
        log "STARTED : $pipeline : $i"
        mkdir -p $raw_files/$i/tmp
        mkdir -p $raw_files/$i/virsorter2_envs

        virsorter run \
        -w $raw_files/$i/ \
        -i $fasta_path/$i.fasta \
        -d /veodata/03/databases/virsorter2 \
        --min-length 1500 \
        -j $SLURM_CPUS_PER_TASK \
        --tmpdir $raw_files/$i/tmp \
        --rm-tmpdir \
        all \
        --conda-prefix $raw_files/$i/virsorter2_envs 

        log "ENDED : $pipeline : $i"
    done
###############################################################################
log "FINISHED: $sublist -----------------------------"
###############################################################################