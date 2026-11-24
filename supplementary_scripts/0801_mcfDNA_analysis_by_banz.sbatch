#!/bin/bash
###############################################################################
#SBATCH --job-name=0801_mcfDNA_analysis_by_banz
#SBATCH --partition=short,standard,long,interactive,gpu,gpu-veo,gpu-test,fat
#SBATCH --cpus-per-task=24
#SBATCH --mem=50G
#SBATCH --output=results/0801_mcfDNA_analysis_by_banz/tmp/slurm/%j.out
#SBATCH --error=results/0801_mcfDNA_analysis_by_banz/tmp/slurm/%j.err
###############################################################################
## for step-02: Kraken2, use 250GB RAM 
## step-00: Initialize variables and environment
    pipeline=0801_mcfDNA_analysis_by_banz
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    # sublist=list.$pipeline.txt
    data_dir=$(grep "my_data_dir" $parameters | awk -F'\t' '{print $2}')
    database=$(grep "my_database" $parameters | awk -F'\t' '{print $2}')
    seqkit=/home/groups/VEO/tools/seqkit/v2.8.2/seqkit
    minimap2=/home/groups/VEO/tools/minimap2/v2.31/minimap2-2.31_x64-linux/minimap2
    samtools=/home/groups/VEO/tools/samtools/v1.17/bin/samtools
    bedtools=/home/groups/VEO/tools/bedtools2/v2.31.0/bin/bedtools
    bracken=/home/groups/VEO/tools/bracken/v3.1/Bracken/bracken
    gtdbtk_db=/veodata/03/databases/gtdbtk/release226
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate perl_v5.32.1
    log "STARTED: $pipeline : $sublist"
    log "data_dir: $data_dir"
    log "database: $database"
###############################################################################
## step-01: calculate number of reads
    for i in $(cat $sublist); do
        if awk -F'\t' -v id="$i" '$1 == id { found=1; exit } END { exit !found }' "$wd/reads.tsv"; then        
            log "$i: reads for this sample already counted"
        else
            log "$i: counting reads for $wd/reads.tsv"
            reads=$(count_reads_from_fastq $data_dir/$i.fastq.gz)
            echo -e "$i\t$reads" | tee -a $wd/reads.tsv
        fi
    done

    if [ ! -f $wd/reads_length_distribution.tsv ]; then
        for i in $(cat $sublist); do
            ${seqkit} \
                fx2tab -n -l "${data_dir}/$i.fastq.gz" |
                awk -F '\t' -v sample="$i" '
                    { n++; a += ($NF >= 35); b += ($NF >= 50); c += ($NF >= 100); d += ($NF >= 250) }
                    END { printf "%s\t%d\t%d\t%d\t%d\t%d\n", sample, n, a, b, c, d }' |
                tee -a $wd/reads_length_distribution.tsv
        done
    fi

    ## create plots for the read length distribution
        # if [ ! -f ${wd}/stacked_barplot_log.png ]; then
        #     source /home/groups/VEO/tools/biopython/myenv/bin/activate
        #     python ${suppl_scripts}/${pipeline}.stacked_barplot.py \
        #     -i ${wd}/reads_length_distribution.tsv \
        #     -o ${wd}/
        # fi

###############################################################################
## step-02: run kraken2 for each sample if not already done
    for i in $(cat $sublist); do
        mkdir -p $raw_files/$i > /dev/null 2>&1
        if [ ! -f $raw_files/$i/$i.kreport ]; then
            setsid \
            $tools/kraken2/v2.1.2/kraken2 \
            --db ${database} \
            --report-minimizer-data \
            --minimum-hit-groups 6 \
            --threads $SLURM_CPUS_PER_TASK \
            --output $raw_files/$i/$i.kraken.out \
            --report $raw_files/$i/$i.kreport \
            $data_dir/$i.fastq.gz \
            --confidence 0.05 \
            & my_pid=$!
            pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
            accurate_log_usage_by_pgid "$pgid" $resource_log/$i.kraken2.tsv
            echo "my_pid: $my_pid"
            echo "pgid: $pgid"

            else
            log "$i: kraken2 output already exists"
        fi
    done

###############################################################################
## step-03: Genus/Species level estimation
    for i in $(cat $sublist); do
        if [ ! -f ${raw_files}/${i}/${i}_G.bracken ]; then
            ${bracken} \
            -d ${database} \
            -i ${raw_files}/${i}/${i}.kreport \
            -r 150 \
            -l G \
            -o ${raw_files}/${i}/${i}_G.bracken \
            -w ${raw_files}/${i}/${i}_G.breport \
            -t $SLURM_CPUS_PER_TASK

            else
                log "$i: Genus level Bracken output already exists"
        fi 

        if [ ! -f ${raw_files}/${i}/${i}_S.bracken ]; then
            ${bracken} \
            -d ${database} \
            -i ${raw_files}/${i}/${i}.kreport \
            -r 150 \
            -l S \
            -o ${raw_files}/${i}/${i}_S.bracken \
            -w ${raw_files}/${i}/${i}_S.breport \
            -t $SLURM_CPUS_PER_TASK
            else
                log "$i: Species level Bracken output already exists"
        fi
    done
###############################################################################
## step-04: OPTIONAL: alpha diversity analysis
    # source /home/groups/VEO/tools/biopython/myenv/bin/activate
    # for i in $(cat $sublist); do
    # if [ ! -f ${raw_files}/${i}/${i}_alpha-diversity.txt ]; then
    #     > ${raw_files}/${i}/${i}_alpha-diversity.txt
    #     log "Processing $i for alpha diversity"

    #     $tools/krakentools/v1.2/KrakenTools/DiversityTools/alpha_diversity.py \
    #     -f ${raw_files}/${i}/${i}_S.bracken \
    #     -a BP \
    #     >> $raw_files/${i}/${i}_alpha-diversity.txt

    #     $tools/krakentools/v1.2/KrakenTools/DiversityTools/alpha_diversity.py \
    #     -f ${raw_files}/${i}/${i}_S.bracken \
    #     -a Sh \
    #     >> $raw_files/${i}/${i}_alpha-diversity.txt

    #     $tools/krakentools/v1.2/KrakenTools/DiversityTools/alpha_diversity.py \
    #     -f ${raw_files}/${i}/${i}_S.bracken \
    #     -a F \
    #     |  grep -v "...loading" \
    #     >> $raw_files/${i}/${i}_alpha-diversity.txt

    #     $tools/krakentools/v1.2/KrakenTools/DiversityTools/alpha_diversity.py \
    #     -f ${raw_files}/${i}/${i}_S.bracken \
    #     -a ISi \
    #     >> $raw_files/${i}/${i}_alpha-diversity.txt
        
    #     else
    #     log "$i: Alpha diversity output already exists"
    # fi
    # done
    # deactivate
###############################################################################
## step-05: Generate Krona plots from Bracken results
    source /vast/xa73pav/tools/miniconda3/etc/profile.d/conda.sh
    conda activate /vast/xa73pav/tools/miniconda3/envs/krona_v2.8.1
    for i in $(cat $sublist); do
        if [ ! -f ${raw_files}/${i}/${i}.krona.html ]; then 
            python3 ${tools}/krakentools/v1.2/KrakenTools/kreport2krona.py \
            -r ${raw_files}/${i}/${i}_S.breport \
            -o ${raw_files}/${i}/${i}.b.krona.txt \
            --no-intermediate-ranks

            ktImportText \
            ${raw_files}/${i}/${i}.b.krona.txt \
            -o ${raw_files}/${i}/${i}.krona.html
            
            else
            log "$i: Krona plot already exists at ${raw_files}/${i}/${i}.krona.html"
        fi
    done
    conda deactivate
###############################################################################
## step-06: extract reads
    for i in $(cat $sublist ); do
    ## Genus
    if [ -f ${raw_files}/${i}/${i}_G.bracken ] ; then
        for taxon_id in $(awk -F'\t' 'NR>1 {print $2}' ${raw_files}/${i}/${i}_G.bracken | grep -v "9605" ); do
            if [ ! -f ${raw_files}/${i}/${i}_extracted_G_${taxon_id}.fa ]; then
                species=$(grep -w "$taxon_id" ${raw_files}/${i}/${i}_G.bracken | awk -F'\t' '{print $1}')

                log "Extracting reads for $i taxon $taxon_id"
                ${tools}/krakentools/v1.2/KrakenTools/extract_kraken_reads.py \
                -k $raw_files/${i}/${i}.kraken.out \
                --include-children \
                --include-parents \
                -s $data_dir/$i.fastq.gz \
                -t $taxon_id \
                -r $raw_files/${i}/${i}.kreport \
                -o ${raw_files}/${i}/${i}_extracted_G_${taxon_id}.fa 
            fi
        done
        else
        log "for $i no genus identified"
    fi

                    ## @Swapnil, Species reads are not really being used downstream, so this section is commented out
                    ## species
                        # if [ -f ${raw_files}/${i}/${i}_S.bracken ] && [ ! -s ${raw_files}/${i}/${i}_extracted_S_${taxon_id}.fa ]; then
                        #     for taxon_id in $(awk -F'\t' 'NR>1 {print $2}' ${raw_files}/${i}/${i}_S.bracken | grep -v "9606" ); do
                        #         species=$(grep -w "$taxon_id" ${raw_files}/${i}/${i}_S.bracken | awk -F'\t' '{print $1}')

                        #         log "Extracting reads for $i taxon $taxon_id"
                        #         ${tools}/krakentools/v1.2/KrakenTools/extract_kraken_reads.py \
                        #         -k $raw_files/${i}/${i}.kraken.out \
                        #         --include-children \
                        #         --include-parents \
                        #         -s $data_dir/$i.fastq.gz \
                        #         -t $taxon_id \
                        #         -r $raw_files/${i}/${i}.kreport \
                        #         -o $raw_files/${i}/${i}_extracted_S_${taxon_id}.fa \
                        #         > /dev/null 2>&1

                        #     done
                        #     else
                        #     log "for $i no species identified"
                        # fi    
    done
###############################################################################
## step-07: mapping reads to reference genomes
    for i in $(cat $sublist ); do
    if [ ! -f ${raw_files}/${i}/00_G_summary.tsv ]; then
        echo -e "Sample\tGenus\tPrimary_mapped_reads" > ${raw_files}/${i}/00_G_summary.tsv
        ## mapping against collective species of the Genus (concatenated single fasta for all sepcies)
        for genus in $(awk -F'\t' 'NR>1 {print $1}' ${raw_files}/${i}/${i}_G.bracken | grep -vwE "Homo|Pan"); do

            genus_taxon_id=$(grep $genus ${raw_files}/${i}/${i}_G.bracken | awk -F'\t' '{print $2}')

            (${minimap2} \
            -ax map-ont \
            -t ${SLURM_CPUS_PER_TASK} \
            ${gtdbtk_db}/mcfDNA_databases/genus/${genus}.fasta \
            ${raw_files}/${i}/${i}_extracted_G_${genus_taxon_id}.fa \
            | ${samtools} view -bhS -q 60 -@ ${SLURM_CPUS_PER_TASK} \
            | ${samtools} sort -@ ${SLURM_CPUS_PER_TASK} \
            -o $raw_files/${i}/${i}_extracted_G_${genus}_${genus_taxon_id}.bam )  > /dev/null 2>&1

            primary_mapped_reads=$(samtools view -c -F 2308 $raw_files/${i}/${i}_extracted_G_${genus}_${genus_taxon_id}.bam)
            if [ $primary_mapped_reads -gt 5 ]; then
                echo -e "$i\t$genus\t$primary_mapped_reads" | tee -a $raw_files/${i}/00_G_summary.tsv
            fi
            
            rm $raw_files/${i}/${i}_extracted_G_${genus}_${genus_taxon_id}.bam

        done

        else
        log "$i: mapping reads to reference Genus: already done"
    fi
    done 

    ## mapping against individual speices of the Genus (individual fasta for individual sepcies)
    for i in $(cat $sublist ); do
        if [ ! -f ${raw_files}/${i}/00_S_summary.tsv ]; then
            echo -e "Sample\tSpecies\tPrimary_mapped_reads" > ${raw_files}/${i}/00_S_summary.tsv
            if [ -f ${raw_files}/${i}/${i}_G.bracken ]; then
                for genus in $(awk -F'\t' 'NR>1 {print $1}' ${raw_files}/${i}/${i}_G.bracken | grep -vwE "Homo|Pan"); do
                    genus_taxon_id=$(grep $genus ${raw_files}/${i}/${i}_G.bracken | awk -F'\t'  '{print $2}')
                    for individual_species in ${gtdbtk_db}/mcfDNA_databases/species/${genus}*.fasta; do
                        species=$(basename $individual_species .fasta)

                        (${minimap2} \
                        -ax map-ont \
                        -t ${SLURM_CPUS_PER_TASK} \
                        $individual_species \
                        ${raw_files}/${i}/${i}_extracted_G_${genus_taxon_id}.fa \
                        | ${samtools} view -bhS -q 60 -@ ${SLURM_CPUS_PER_TASK} \
                        | ${samtools} sort -@ ${SLURM_CPUS_PER_TASK} \
                        -o $raw_files/${i}/${i}_extracted_${species}_${genus_taxon_id}.bam ) > /dev/null 2>&1

                        if [ -f $raw_files/${i}/${i}_extracted_${species}_${genus_taxon_id}.bam ]; then
                            # Convert BAM to BED for coverage analysis
                            ${samtools} view -b -F 2308 $raw_files/${i}/${i}_extracted_${species}_${genus_taxon_id}.bam |
                            ${bedtools} bamtobed -i stdin > $raw_files/${i}/${i}_extracted_${species}_${genus_taxon_id}.bam.bed

                            primary_mapped_reads=$(${samtools} view -c -F 2308 $raw_files/${i}/${i}_extracted_${species}_${genus_taxon_id}.bam)
                            if [ $primary_mapped_reads -gt 5 ]; then
                                echo -e "$i\t$species\t$primary_mapped_reads" | tee -a $raw_files/${i}/00_S_summary.tsv
                            fi
                        fi
                        rm $raw_files/${i}/${i}_extracted_${species}_${genus_taxon_id}.bam
                    done
                done
            else
            log "$i: mapping reads to reference Species: already done"
            fi
        fi
    done

    ## sumarise
        for i in $(cat $sublist ); do
            echo "Processing sample $i"
            python3 ${suppl_scripts}/${pipeline}.analyze_genus_counts.py \
            -s ${raw_files}/${i}/00_S_summary.tsv \
            -g ${raw_files}/${i}/00_G_summary.tsv \
            -k ${raw_files}/${i}/${i}_G.bracken \
            -o ${raw_files}/${i}/00_genus_counts.tsv \
            --detailed --top-only

            tail -n +2 $raw_files/${i}/00_genus_counts.tsv | sed 's/^/'"$i"'\t/' >> ${wd}/summary.tsv
        done
###############################################################################
## generate Circos coverage plots

###############################################################################
