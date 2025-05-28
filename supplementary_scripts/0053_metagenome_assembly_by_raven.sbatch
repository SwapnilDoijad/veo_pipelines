#!/bin/bash
#SBATCH --job-name 0053_metagenome_assembly_by_raven
#SBATCH --partition=fat
#SBATCH --output=results/0053_metagenome_assembly_by_raven/tmp/slurm/0053_metagenome_assembly_by_raven.%j.out
#SBATCH --error=results/0053_metagenome_assembly_by_raven/tmp/slurm/0053_metagenome_assembly_by_raven.%j.err
#SBATCH --mem=1000G
#SBATCH --cpus-per-task=4
#-- Command section ------------------------
	pipeline=0053_metagenome_assembly_by_raven
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh

    sublist=$wd/tmp/lists/ABC
    fastq_path=$( grep my_fastq_path $parameters | awk '{print $2}' )

    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate raven_v1.8.3

    for F1 in $(cat $sublist); do
        log "running raven-assembler for $F1"

        mkdir results/0053_metagenome_assembly_by_raven/raw_files/$F1

        raven -t $SLURM_CPUS_PER_TASK \
        $fastq_path/$F1.fastq.gz \
        > $raw_files/$F1/$F1.fasta \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$id.raven.tsv 

        log "The raven-assembler for $F1 is finished"
	done