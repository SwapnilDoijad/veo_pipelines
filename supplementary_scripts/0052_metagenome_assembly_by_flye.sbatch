#!/bin/bash
#SBATCH --job-name=0052_metagenome_assembly_by_flye
#SBATCH --partition=standard,long,gpu,gpu-veo,gpu-test
#SBATCH --output=results/0052_metagenome_assembly_by_flye/tmp/slurm/%j.out.0052_metagenome_assembly_by_flye
#SBATCH --error=results/0052_metagenome_assembly_by_flye/tmp/slurm/%j.err.0052_metagenome_assembly_by_flye
#SBATCH --mem=240G
#SBATCH --cpus-per-task=40
###############################################################################
## header
    pipeline=0052_metagenome_assembly_by_flye
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fastq_file_path=$(grep "my_fastq_path" $parameters | awk '{print $2}')

    source /home/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate flye_v2.9.2
###############################################################################
    log "STARTED: $pipeline : $list"
###############################################################################

    for i in $(cat $sublist); do
        if [ ! -f $raw_files/$i/assembly.fasta ]; then 
            log "running flye-assembler for $i"
            flye --meta \
            -t $SLURM_CPUS_PER_TASK \
            --nano-raw $fastq_file_path/$i.fastq.gz \
            --out-dir $raw_files/$i
            log "The flye-assembler for $i is finished"
            else
            log "ALREADY FINISHED: the flye-assembler for $i"
        fi 
    done
###############################################################################
    log "FINISHED: $pipeline " && clean
###############################################################################