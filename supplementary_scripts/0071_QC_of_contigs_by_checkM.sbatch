#!/bin/bash
#SBATCH --job-name 0071_QC_by_checkM
#SBATCH --partition=standard
#SBATCH --output $wd/tmp/slurm/%j.out.0071_QC_by_checkM
#SBATCH --error  $wd/tmp/slurm/%j.err.0071_QC_by_checkM
#SBATCH --cpus-per-task=25
###############################################################################
## step-01: preparation
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    pipeline=0071_QC_of_contigs_by_checkM
    wd=results/$pipeline

    parameter_file=tmp/parameters/$pipeline.*
    fasta_path=$(grep my_fasta_path $parameter_file | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC

###############################################################################
## run
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate checkm_v1.2.2
    
    log "STARTED : sbatch for 0071_QC_by_checkM for $sublist"

    for i in $(cat $sublist); do
        if [ ! -f $wd/raw_files/$i/lineage.ms ]; then
            log "RUNNING : $pipeline : $i"
            (mkdir -p $wd/fasta/$i) > /dev/null 2>&1

            cp $fasta_path/"$i"*.fasta $wd/fasta/$i/
            rm $wd/fasta/$i/*.tooShort.*
            rm $wd/fasta/$i/*.unbinned.*

            checkm lineage_wf \
            -t $SLURM_CPUS_PER_TASK \
            -x fasta \
            -f $wd/raw_files/$i/$i.tsv \
            --tab_table \
            $wd/fasta/$i/ \
            $wd/raw_files/$i

            else
            log "FINISHED : $pipeline : $i"
        fi
    done
###############################################################################
## step-02: post-processing : 

    for i in $(cat list.fastq.txt); do 

        ## 95Compl_5Conta_5hetero
        awk -F'\t' 'NR==1 || ($6>95 && $7<95 && $8<95) {print $0}' $wd/raw_files/$i/$i.tsv | grep -v "unbinned" \
        > $wd/raw_files/$i/$i.95Compl_5Conta_5hetero.tsv

        awk 'NR>1 {print $1}' $wd/raw_files/$i/$i.95Compl_5Conta_5hetero.tsv \
        > $wd/tmp/$i.95Compl_5Conta_5hetero.txt

        ## 70Compl_30Conta_25hetero
        awk -F'\t' 'NR==1 || ($6>70 && $7<70 && $8<25) {print $0}' $wd/raw_files/$i/$i.tsv | grep -v "unbinned" \
        > $wd/raw_files/$i/$i.70Compl_30Conta_25hetero.tsv

        awk 'NR>1 {print $1}' $wd/raw_files/$i/$i.70Compl_30Conta_25hetero.tsv \
        > $wd/tmp/$i.70Compl_30Conta_25hetero.txt


        ## 50Compl_50Conta_50hetero
        awk -F'\t' 'NR==1 || ($6>50 && $7<50 && $8<50) {print $0}' $wd/raw_files/$i/$i.tsv | grep -v "unbinned" \
        > $wd/raw_files/$i/$i.50Compl_50Conta_50hetero.tsv

        awk 'NR>1 {print $1}' $wd/raw_files/$i/$i.50Compl_50Conta_50hetero.tsv \
        > $wd/tmp/$i.50Compl_50Conta_50hetero.txt
    done 

    cat $wd/tmp/*.70Compl_30Conta_25hetero.txt \
    > $wd/tmp/all.70Compl_30Conta_25hetero.txt

    cat $wd/tmp/*.95Compl_5Conta_5hetero.txt \
    > $wd/tmp/all.95Compl_5Conta_5hetero.txt

    cat $wd/tmp/*.50Compl_50Conta_50hetero.txt \
    > $wd/tmp/all.50Compl_50Conta_50hetero.txt

###############################################################################
    log "Ended: sbatch for 0071_QC_by_checkM for $sublist"
###############################################################################