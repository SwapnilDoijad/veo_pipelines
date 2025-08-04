#!/bin/bash
#SBATCH --job-name 0067_identification_contigs_by_CAT_BAT_RAT
#SBATCH --partition=gpu,gpu-veo,interactive,standard,long
#SBATCH --output=results/0067_identification_contigs_by_CAT_BAT_RAT/tmp/slurm/%j.out
#SBATCH --error=results/0067_identification_contigs_by_CAT_BAT_RAT/tmp/slurm/%j.err
#SBATCH --mem=250G
#SBATCH --cpus-per-task=40
###############################################################################
## step-01: preparation
    pipeline=0067_identification_contigs_by_CAT_BAT_RAT
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    
    sublist=$wd/tmp/lists/ABC
    choise=$(grep my_choise $parameters | awk '{print $2}')

    nr_database=/veodata/03/databases/cat_bat_rat/v20240405/db/
    tax_database=/veodata/03/databases/cat_bat_rat/v20240405/tax/
    diamond=/home/groups/VEO/tools/cat_bat_rat/diamond_v2.1.8.162
    prodigal=/home/groups/VEO/tools/prodigal/v2.6.3/prodigal
###############################################################################
## step-02: run CAT 
    log "STARTED : $pipeline : sbatch for $sublist"
    for i in $(cat $sublist); do
        log "RUNNING : $pipeline for $i"

        mkdir $raw_files/$i/CAT/ > /dev/null 2>&1
        file_path=$(grep -w "$i" $parameters | awk '{print $2}')
        bin_path=$(grep bins $parameters  | grep -v "#" | awk '{print $2}')
        read_path=$(grep paired_fastq_read_path $parameters | grep -v "#" | awk '{print $2}')

        ## CAT
        if [ "$choise" = "all" ] || [ "$choise" = "CAT" ]; then
        if [ ! -f $raw_files/$i/CAT/$i.contig2classification.txt ] ; then 
            log  "RUNNING : $pipeline : $i"
            mkdir -p $raw_files/$i/CAT

            /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack \
            contigs \
            -f 0.1 \
            -c $file_path \
            -d $nr_database \
            -t $tax_database \
            --path_to_prodigal $prodigal \
            --path_to_diamond $diamond \
            -n $SLURM_CPUS_PER_TASK \
            --out_prefix $raw_files/$i/CAT/$i

            /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack add_names \
            -i $raw_files/$i/CAT/$i.contig2classification.txt \
            -o $raw_files/$i/CAT/$i.contig2classification.official_names.txt \
            -t $tax_database \
            --only_official

            /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack summarise \
            -c $file_path \
            -i $raw_files/$i/CAT/$i.contig2classification.official_names.txt \
            -o $raw_files/$i/CAT/$i.summary.txt

            log "FINISHED : $pipeline : $i"
            else
            log "ALREADY FINISHED : $pipeline : $i"
        fi
        fi

        if [ "$choise" = "all" ] || [ "$choise" = "BAT" ]; then
        if [ ! -d $raw_files/$i/BAT ] ; then 
            log "STARTED : $pipeline : $i : BAT "
            mkdir -p $raw_files/$i/BAT > /dev/null 2>&1

            /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack bins \
            -f 0.1 \
            -b $bin_path/raw_files/$i/ \
            -d $nr_database \
            -t $tax_database \
            -s .fa \
            -p $raw_files/$i/CAT/$i.predicted_proteins.faa \
            -a $raw_files/$i/CAT/$i.alignment.diamond \
            -o $raw_files/$i/BAT/$i

            /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack add_names \
            -i $raw_files/$i/BAT/$i.bin2classification.txt \
            -o $raw_files/$i/BAT/$i.contig2classification.official_names.txt \
            -t $tax_database \
            --only_official

            /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack summarise \
            -i $raw_files/$i/BAT/$i.contig2classification.official_names.txt \
            -o $raw_files/$i/BAT/$i.summary.txt

            else
            log "ALREADY FINISHED : $pipeline : $i : BAT "
        fi
        fi

        if [ "$choise" = "all" ] || [ "$choise" = "RAT" ]; then
        if [ ! -d $raw_files/$i/RAT ] ; then
            log "RUNNING : RAT for $i"

            mkdir -p $raw_files/$i/RAT > /dev/null 2>&1
            
            /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack reads \
            --mode mcr \
            -b $bin_path/raw_files/$i/ \
            -c $file_path \
            -1 $read_path/"$i"_R1.fastq.gz \
            -2 $read_path/"$i"_R2.fastq.gz \
            -d $nr_database \
            -t $tax_database \
            -s .fa \
            --path_to_bwa /home/groups/VEO/tools/bwa/v0.7.17/bwa \
            --path_to_samtools /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
            --path_to_prodigal $prodigal \
            --path_to_diamond $diamond \
            --c2c $raw_files/$i/CAT/$i.contig2classification.txt \
            --b2c $raw_files/$i/BAT/$i.bin2classification.txt \
            -o $raw_files/$i/RAT/$i
            else
                log "ALREADY FINISHED : RAT for $i"
        fi
        fi
            log "FINISHED : $pipeline for $i"
    done

    log "ENDED : $pipeline : sbatch for $sublist"
###############################################################################


## 20240409
## notes: This set up worked
    # nr_database=/veodata/03/databases/cat_bat_rat/v20210107/CAT_prepare_20210107/2021-01-07_CAT_database/
    # tax_database=/veodata/03/databases/cat_bat_rat/v20210107/CAT_prepare_20210107/2021-01-07_taxonomy/
    # diamond=/veodata/03/databases/cat_bat_rat/v20210107/CAT_prepare_20210107/Diamond_2.0.6/diamond



# /home/groups/VEO/tools/cat_bat_rat/CAT_pack/CAT_pack/CAT_pack reads \
# --mode mcr -b results/0059_metagenome_binning_by_metabat_for_megahit_assemblies/raw_files/zr11465-01/ \
# -c results/0055_metagenome_assembly_by_megahit_for_illumina/all_fasta/zr11465-01.contigs.fasta \
# -1 results/0025_QC_of_paired-fastq_by_fastp/raw_files/zr11465-01_R1.fastq.gz \
# -2 results/0025_QC_of_paired-fastq_by_fastp/raw_files/zr11465-01_R2.fastq.gz \
# -d /veodata/03/databases/cat_bat_rat/v20240405/db/ \
# -t /veodata/03/databases/cat_bat_rat/v20240405/tax/ \
# --path_to_prodigal /home/groups/VEO/tools/prodigal/v2.6.3/prodigal \
# --path_to_diamond /home/groups/VEO/tools/cat_bat_rat/diamond_v2.1.8.162 \
# --path_to_bwa /home/groups/VEO/tools/bwa/v0.7.17/bwa \
# --path_to_samtools /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
# --c2c results/0067_identification_contigs_by_CAT_BAT_RAT/raw_files/zr11465-01/CAT/zr11465-01.contig2classification.txt \
# --b2c results/0067_identification_contigs_by_CAT_BAT_RAT/raw_files/zr11465-01/BAT/zr11465-01.bin2classification.txt \
# -o results/0067_identification_contigs_by_CAT_BAT_RAT/raw_files/zr11465-01/RAT/zr11465-01c