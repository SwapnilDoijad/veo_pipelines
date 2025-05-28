#!/bin/bash
#SBATCH --job-name=0132_d
#SBATCH --partition=short,long,interactive
#SBATCH --output=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.out
#SBATCH --error=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.err
#SBATCH --cpus-per-task=24
#SBATCH --mem=40G
###############################################################################  
## header
    pipeline=0132_phylogeny_for_phage_by_shared_genome_content
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    mash_tool_path=/home/groups/VEO/tools/mash/v2.3
    list=list.$pipeline.txt
    sublist=$wd/tmp/lists/ABC
###############################################################################  
## calculating distance
    # -p is threads
    for i in $(cat $list); do
        for i2 in $(cat $sublist); do
            if [ ! -f $raw_files/distance/$i.$i2.dist.tsv ] ; then
                
                $mash_tool_path/mash dist \
                -p $SLURM_CPUS_PER_TASK \
                $raw_files/msh/$i.mash_sketch.msh \
                $raw_files/msh/$i2.mash_sketch.msh \
                > $raw_files/distance/$i.$i2.dist.tsv

            fi
        done
    done
############################################################################### 