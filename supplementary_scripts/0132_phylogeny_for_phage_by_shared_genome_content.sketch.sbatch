#!/bin/bash
#SBATCH --job-name=0132_s
#SBATCH --partition=interactive,short,long
#SBATCH --output=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.out
#SBATCH --error=results/0132_phylogeny_for_phage_by_shared_genome_content/tmp/slurm/%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=1G
###############################################################################  
## header
    pipeline=0132_phylogeny_for_phage_by_shared_genome_content
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    mash_tool_path=/home/groups/VEO/tools/mash/v2.3
    sublist=$wd/tmp/lists/ABC
    fasta_file_path=$(grep "my_fasta_path" $parameters | awk '{print $2}')
###############################################################################  
## sketching

    for i in $(cat $sublist); do
        if [ ! -f $raw_files/msh/$i.mash_sketch.msh ] ; then 
            $mash_tool_path/mash sketch -s 1000 -p $SLURM_CPUS_PER_TASK \
            -o $raw_files/msh/$i.mash_sketch.msh \
            $fasta_file_path/$i.fasta 
        fi
    done

###############################################################################