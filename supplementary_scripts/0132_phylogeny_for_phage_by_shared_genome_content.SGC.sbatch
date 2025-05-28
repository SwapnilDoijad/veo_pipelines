#!/bin/bash
#SBATCH --job-name=0132_g
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
    list=list.$pipeline.txt
    sublist=$wd/tmp/lists/ABC
###############################################################################  
## sketching
    for i in $(cat $list ); do
        for i2 in $(cat $sublist ); do
            log "RUNNING: calculating SGC_ANI $i"

            awk '{print $5}' $raw_files/distance/$i.$i2.dist.tsv \
            | awk -F'/' '{print $1*100/1000 }' | tr ' ' '\n' \
            > $raw_files/SGC_ANI/tmp/$i.$i2.SGC.txt

            awk '{print (1-$3)*100}' $raw_files/distance/$i.$i2.dist.tsv \
            | tr ' ' '\n' > $raw_files/SGC_ANI/tmp/$i.$i2.ANI.txt

            paste $raw_files/SGC_ANI/tmp/$i.$i2.SGC.txt \
            $raw_files/SGC_ANI/tmp/$i.$i2.ANI.txt \
            > $raw_files/SGC_ANI/tmp/$i.$i2.SGC_ANI.txt

            awk '{print $1*$2/100}' $raw_files/SGC_ANI/tmp/$i.$i2.SGC_ANI.txt \
            > $raw_files/SGC_ANI/tmp/$i.$i2.txt

            cat $raw_files/SGC_ANI/tmp/$i.$i2.txt \
            >> $raw_files/SGC_ANI/tmp/$i2.txt
        done 
    done

###############################################################################