#!/bin/bash
#SBATCH --job-name 0059_metagenome_binning_by_metabat_for_megahit_assemblies
#SBATCH --partition=standard
#SBATCH --output results/0059_metagenome_binning_by_metabat_for_megahit_assemblies/tmp/slurm/%j.out
#SBATCH --error results/0059_metagenome_binning_by_metabat_for_megahit_assemblies/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
#-- Command section ------------------------

###############################################################################
## header
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "SBATCH STARTED : 0059_metagenome_binning_by_metabat_for_megahit_assemblies -----------------------------------"
###############################################################################
    pipeline=0059_metagenome_binning_by_metabat_for_megahit_assemblies
    wd=results/$pipeline
    sublist=$wd/tmp/lists/ABC

    for i in $(cat $sublist); do
        if [ ! -d $wd/raw_files/$i ] ; then 
            log "STARTED : metabat assembler for $i"
            
            mkdir $wd/raw_files/$i 

            /home/groups/VEO/tools/metabat/v2/bin/metabat2 \
            -i results/0055_metagenome_assembly_by_megahit_for_illumina/raw_files/$i/$i.contigs.fa \
            -o $wd/raw_files/$i/$i \
            --minContig 1500 \
            --minSmallContig 500 \
            --unbinned

            log "FINISHED : metabat assembler for $i"
            else
            log "ALREADY FINISHED : metabat assembler for $i"
        fi

    done

    echo -e "IDs\tnumber_of_contigs" > $wd/summary.tsv
    mkdir $wd/all_fasta > /dev/null 2>&1
    for i in $(cat $sublist); do
        if [ ! -f $wd/all_fasta/$i.1.fasta ] ; then
            cp $wd/raw_files/$i/$i.*.fa $wd/all_fasta/$i.*.fasta

            number_of_contigs=$( grep -c ">" $wd/raw_files/$i/$i.contigs.fa )
            echo -e "$i\t$number_of_contigs" >> $wd/summary.tsv
            else 
            echo -e "$i\tNA" >> $wd/summary.tsv
        fi 
    done
#########################################`######################################
## footer
    log "SBATCH ENDED : 0059_metagenome_binning_by_metabat_for_megahit_assemblies ----------------------"
###############################################################################




