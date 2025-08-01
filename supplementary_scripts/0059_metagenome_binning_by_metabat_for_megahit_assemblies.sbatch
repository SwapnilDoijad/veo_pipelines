#!/bin/bash
#SBATCH --job-name=0059_metagenome_binning_by_metabat_for_megahit_assemblies
#SBATCH --partition=gpu-veo,standard,long,gpu,gpu-test
#SBATCH --output=results/0059_metagenome_binning_by_metabat_for_megahit_assemblies/tmp/slurm/%j.out
#SBATCH --error=results/0059_metagenome_binning_by_metabat_for_megahit_assemblies/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################
## header
    pipeline=0059_metagenome_binning_by_metabat_for_megahit_assemblies
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_path=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
    log "SBATCH STARTED : 0059_metagenome_binning_by_metabat_for_megahit_assemblies -----------------------------------"
###############################################################################
    sublist=$wd/tmp/lists/ABC

    for i in $(cat $sublist); do
        if [ ! -d $raw_files/$i ] ; then 
            log "STARTED : metabat assembler for $i"
            
            mkdir $raw_files/$i 

            /home/groups/VEO/tools/metabat/v2/bin/metabat2 \
            -i $fasta_path/$i.fasta \
            -o $raw_files/$i/$i \
            --minContig 1500 \
            --minSmallContig 500 \
            --unbinned \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.megabat2.tsv 

            mkdir $raw_files/$i/metaquast
            
            python3 $tools/quast/v5.2.0/metaquast.py \
            --silent \
            --circos \
            -o $raw_files/$i/metaquast \
            $raw_files/$i/*.fa \
			& my_pid=$!
			get_resource_stat $my_pid $wd/tmp/resource_log/$i.metaquast.tsv 

            log "FINISHED : metabat assembler for $i"
            else
            log "ALREADY FINISHED : metabat assembler for $i"
        fi

    done

    echo -e "IDs\tnumber_of_contigs" > $wd/summary.tsv
    mkdir $wd/all_fasta > /dev/null 2>&1
    for i in $(cat $sublist); do
        if [ ! -f $wd/all_fasta/$i.1.fasta ] ; then
            cp $raw_files/$i/$i.*.fa $wd/all_fasta/$i.*.fasta

            number_of_contigs=$( grep -c ">" $raw_files/$i/$i.contigs.fa )
            echo -e "$i\t$number_of_contigs" >> $wd/summary.tsv
            else 
            echo -e "$i\tNA" >> $wd/summary.tsv
        fi 
    done
###############################################################################
## footer
    log "SBATCH ENDED : 0059_metagenome_binning_by_metabat_for_megahit_assemblies" && clean
###############################################################################




