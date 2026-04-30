#!/bin/bash
#SBATCH --job-name=0230_MLST_by_mlst
#SBATCH --partition=standard,long,gpu,gpu-veo,gpu-test
#SBATCH --output=results/0230_MLST_by_mlst/tmp/slurm/%j.out
#SBATCH --error=results/0230_MLST_by_mlst/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=50G
###############################################################################
## step-01: preparation
    pipeline=0230_MLST_by_mlst
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    scheme=$( grep my_mlst_scheme $parameters | awk '{print $2}' )
    sublist=$wd/tmp/lists/ABC

    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate mlst_v25

###############################################################################
    log "STARTED : $pipeline" 
###############################################################################
    my_dir_id=$(echo $sublist | awk -F'/' '{print $NF}')
    
    if [ ! -d "$raw_files/tmp/$my_dir_id" ]; then
        mkdir -p $raw_files/tmp/$my_dir_id
        
        xargs -d '\n' -I {} cp "$fasta_dir/{}.fasta" -t "$raw_files/tmp/$my_dir_id/" < "$sublist"
    fi

    > $raw_files/$my_dir_id.tsv
	setsid \
	mlst \
	--scheme $scheme \
	--threads $SLURM_CPUS_PER_TASK \
	$raw_files/tmp/$my_dir_id/* \
	> $raw_files/$my_dir_id.tsv \
    & my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" $wd/tmp/resource_log/mlst.$my_dir_id.tsv 1

###############################################################################
    log "FINISHED : $pipeline" && clean
###############################################################################
