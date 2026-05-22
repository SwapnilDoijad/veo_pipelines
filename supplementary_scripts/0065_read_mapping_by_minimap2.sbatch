#!/bin/bash
#SBATCH --job-name=0065_read_mapping_by_minimap2
#SBATCH --partition=standard,long,gpu,gpu-veo,gpu-test,fat
#SBATCH --output=results/0065_read_mapping_by_minimap2/tmp/slurm/%j.out.txt
#SBATCH --error=results/0065_read_mapping_by_minimap2/tmp/slurm/%j.err.txt
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
#SBATCH --exclusive
###############################################################################
pipeline=0065_read_mapping_by_minimap2
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
data_type=$(grep -w "my_data_type" $parameters | awk '{print $2}')
SNP_analysis=$(grep -w "my_SNP_analysis" $parameters | awk '{print $2}')
snp_annotation=$(grep -w "my_snp_annotation" $parameters | awk '{print $2}')
read_type=$( grep -w "my_read_type" $parameters | awk '{print $2}' )

    ## read_type_input
    if [ "$read_type" = "pacbio" ]; then
        read_type_input="map-pb"
    elif [ "$read_type" = "nanopore" ]; then
        read_type_input="map-ont"
    elif [ "$read_type" = "illumina" ]; then
        read_type_input="sr"
    fi
###############################################################################
    log "The run for sublist : $sublist is started"
###############################################################################
    # echo "Swapnil, sometime some files are not processed, check if first vcf file is empty. It should not be empty raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf"
    # exit

    while IFS= read -r line; do
        assembly_id_path=$( echo $line | awk '{print $1}' | xargs -I{} dirname {} | sort | uniq )
        assembly_id=$( echo $line | awk '{print $1}' | awk -F'/' '{print $NF}' | sed 's/\.fasta//g' | sort | uniq )
        fastq_id_path=$( echo $line | awk '{print $2}' | xargs -I{} dirname {} | tr ' ' '\n' | sort | uniq )
        fastq_id=$( echo $line | awk '{print $2}'| awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' | tr ' ' '\n' |  sort | uniq )

        log "assembly_id_path: $assembly_id_path"
        log "assembly_id: $assembly_id"
        log "fastq_id_path: $fastq_id_path"
        log "fastq_id: $fastq_id"
        log "SLURM_CPUS_PER_TASK: $SLURM_CPUS_PER_TASK"

        if [ ! -f $raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt ] ; then 

            ## Minimap2 is designed to work with both interleaved paired reads and split paired reads for short or long reads.
            ## For paired-end data provided as a single interleaved FASTQ file, minimap2 can properly parse and process the paired reads without requiring any additional steps.
            ## use The -x map-pb preset is optimized for long-read mapping (e.g., PacBio or ONT reads), which typically are not in paired-end format. 
            ## If you're using paired-end reads with this preset, minimap2 will still handle them correctly, as it expects reads to be continuous and will ignore pairing information by default.
            ## create index ## -x map-pb pacBIO reads ## -x sr short reads ## -x map-ont Nanopore reads 
            if [ ! -f $assembly_id_path/"$assembly_id".fasta.mmi ]; then
                log "STARTED : creating index for $assembly_id"
                /home/groups/VEO/tools/minimap2/v2.26/minimap2 \
                -x $read_type_input -t $SLURM_CPUS_PER_TASK \
                -d $raw_files/index_files/$assembly_id.fasta.mmi \
                $assembly_id_path/"$assembly_id".fasta
                log "FINISHED : creating index for $assembly_id"
                else
                echo "ALREADY FINISHED : index for $assembly_id"
            fi

            ## create index for reference fasta file using samtools, needed in addition to minimap2 index, for other tools
            if [ "$SNP_analysis" = "Yes" ] && [ ! -f $assembly_id_path/"$assembly_id".samtools.dict ]; then
                log "STARTED : creating Samtool index for $assembly_id"
                cp $assembly_id_path/"$assembly_id".fasta \
                $assembly_id_path/"$assembly_id".samtools.fasta

                /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                faidx $assembly_id_path/"$assembly_id".samtools.fasta
                
                conda activate gatk_v4.6.1.0
                gatk CreateSequenceDictionary \
                -R $assembly_id_path/"$assembly_id".samtools.fasta \
                -O $assembly_id_path/"$assembly_id".samtools.dict
                conda deactivate 
                else
                echo "ALREADY FINISHED : Samtool index for $assembly_id"
            fi

            if [ $data_type == "single" ]; then
                ## map files ## -x map-pb pacBIO reads ## -x sr short reads ## -x map-ont Nanopore reads
                if [ ! -f $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam.gz ] ; then
                    log "STARTED : mapping $fastq_id on $assembly_id using minimap2"
                    /home/groups/VEO/tools/minimap2/v2.26/minimap2 -x $read_type_input -a \
                    --secondary=no \
                    -t $SLURM_CPUS_PER_TASK \
                    $raw_files/index_files/$assembly_id.fasta.mmi \
                    $fastq_id_path/$fastq_id.fastq.gz \
                    > $raw_files/sam_files/$assembly_id.$fastq_id.sam
                    log "FINISHED : mapping for $fastq_id on $assembly_id"
                    else 
                    log "ALREADY FINISHED : mapping for $fastq_id on $assembly_id"
                fi 

                elif [ $data_type == "paired" ]; then
            
                # Check if the SAM file already exists
                if [ ! -f $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam.gz ]; then
                    log "STARTED : mapping $fastq_id on $assembly_id using minimap2"

                    fwd_reads=$(echo $line | awk '{print $2}')
                    rev_reads=$(echo $line | awk '{print $3}')
                    echo "fwd_reads: $fwd_reads"
                    echo "rev_reads: $rev_reads"

                    # Run minimap2 for paired-end reads
                    ## for paired end sequencing, -x sr is used (as long reads are not in paired-end format)
                    /home/groups/VEO/tools/minimap2/v2.26/minimap2 -x sr -a \
                    $raw_files/index_files/$assembly_id.fasta.mmi \
                    -t $SLURM_CPUS_PER_TASK \
                    $fwd_reads \
                    $rev_reads \
                    > "$raw_files/sam_files/$assembly_id.$fastq_id.sam" \
                    & my_pid=$!
			        get_resource_stat $my_pid $wd/tmp/resource_log/$assembly_id.minimap2.tsv 

                    check_status "Mapping $fastq_id on $assembly_id"
                else
                    log "ALREADY FINISHED : mapping for $fastq_id on $assembly_id"
                fi
            fi

            if [ ! -f $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam.gz ] ; then 
                ## sort file using samtools
                /home/groups/VEO/tools/samtools/v1.17/bin/samtools sort -@ $SLURM_CPUS_PER_TASK -l 9 -m 5000M \
                -o $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                $raw_files/sam_files/$assembly_id.$fastq_id.sam

                rm -rf $raw_files/sam_files/$assembly_id.$fastq_id.sam

                ## get summary of sorted .bam file using samtools
                /home/groups/VEO/tools/samtools/v1.17/bin/samtools flagstat \
                $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                > $raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt

                /home/groups/VEO/tools/samtools/v1.17/bin/samtools index \
                $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam

                /home/groups/VEO/tools/samtools/v1.17/bin/samtools depth \
                $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                > $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt

                # Verify file is readable and index is usable
                /home/groups/VEO/tools/samtools/v1.17/bin/samtools quickcheck \
                $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam

                if [ $? -eq 0 ]; then
                    /home/groups/VEO/tools/samtools/v1.17/bin/samtools idxstats \
                    $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                    > $raw_files/sam_files_sorted/$assembly_id.$fastq_id.idxstats.txt
                else
                    log "Error: BAM or index not ready for $assembly_id.$fastq_id" | tee -a $wd/errors.txt
                fi
            fi

            if [ -f $raw_files/sam_files_sorted/$assembly_id.$fastq_id.idxstats.txt ]; then 
                total_bases=$(python3 $suppl_scripts/utilities/fastq_get_reads_bases.py $fastq_id_path/$fastq_id.fastq.gz | awk '{print $2}')
                mapped_bases=$(awk '{sum+=$3} END {print sum}' $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt )
                awk -v total_bases="$total_bases" -v mapped_bases="$mapped_bases" '{sum[$1]+=$3; count[$1]++} END {for (contig in sum) print contig, sum[contig]/count[contig], 10000*(sum[contig]/mapped_bases), 10000*sum[contig]/total_bases}' \
                $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt \
                > $raw_files/depth_and_coverage/$assembly_id.$fastq_id.avg_coverage_perBase.txt 

                total_reads=$(python3 $suppl_scripts/utilities/fastq_get_reads_bases.py $fastq_id_path/$fastq_id.fastq.gz | awk '{print $1}')
                mapped_reads=$(awk '{sum+=$3} END {print sum}' $raw_files/sam_files_sorted/$assembly_id.$fastq_id.idxstats.txt | awk '{print $1}')
                awk -v total_reads="$total_reads" -v mapped_reads="$mapped_reads" 'NR==FNR {a[$1]=$0; next} ($1 in a) {print a[$1] "\t" $2, $3, 100*$3/mapped_reads, 100*$3/total_reads}' \
                $raw_files/depth_and_coverage/$assembly_id.$fastq_id.avg_coverage_perBase.txt \
                $raw_files/sam_files_sorted/$assembly_id.$fastq_id.idxstats.txt \
                | sed "s/^/$assembly_id\t/g" > $raw_files/depth_and_coverage/$assembly_id.$fastq_id.stats.tsv

                sed -i '1i assembly_id contig_id avg_cov_perBase_mapped avg_cov_perBase_mapped(CP10K) avg_cov_perBase_TotalBases(CP10K) contig_length reads_mapped %reads_mappedMapped %reads_mappedTotalReads' \
                $raw_files/depth_and_coverage/$assembly_id.$fastq_id.stats.tsv

                sed -i 's/ /\t/g' $raw_files/depth_and_coverage/$assembly_id.$fastq_id.stats.tsv
                rm -rf $raw_files/depth_and_coverage/$assembly_id.$fastq_id.avg_coverage_perBase.txt 
                # rm -rf $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt

                echo "--------------------------------------------------------------------------------" >> $wd/summary.txt
                echo $assembly_id $fastq_id >> $wd/summary.txt
                cat $raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt \
                >> $wd/summary.txt
                echo "--------------------------------------------------------------------------------" >> $wd/summary.txt
                else
                log "Error: idxstats file not found for $assembly_id.$fastq_id" 
            fi
        fi

            ## Generate Pileup File (required for the variant calling and consesus calling) 
                # mpileup -Ou: The -O option outputs uncompressed binary (BCF) format, and -u ensures the output is uncompressed, which allows for piping.
                    /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools mpileup -Ou -f \
                    $assembly_id_path/"$assembly_id".fasta \
                    $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                    -o $raw_files/mpileup/$assembly_id.$fastq_id.bcf

                    /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools call -mv -Oz -o \
                    $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz \
                    $raw_files/mpileup/$assembly_id.$fastq_id.bcf

                    ## Generate Consensus Sequence
                    /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools index $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz

                    cat $assembly_id_path/"$assembly_id".fasta | /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools consensus \
                    -p $assembly_id \
                    $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz \
                    > $raw_files/consensus_sequences/$assembly_id.$fastq_id.consensus.fasta


                                        # ## Generate Insertion and Deletion File
                                        # if [ ! -f $raw_files/InsDel/$assembly_id.$fastq_id.vcf ] ; then
                                        #     echo -e "#ID\tCHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tout" > $raw_files/InsDel/$assembly_id.$fastq_id.vcf
                                        # fi

                                        # /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools \
                                        # view $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz \
                                        # | grep -v "^#" | sed "s/^/$fastq_id\t/" >> $raw_files/InsDel/$assembly_id.$fastq_id.vcf 

                                        # awk 'NR > 1' $raw_files/InsDel/$assembly_id.$fastq_id.vcf >> $raw_files/summary.InsDel.tsv 

        if [ "$SNP_analysis" = "Yes" ] && [ ! -f $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv.split.tsv ] ; then

            if [ ! -f $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf ] ; then 
                log "STARTED : freebayes variant calling for $assembly_id.$fastq_id"
                
                /home/groups/VEO/tools/freebayes/v1.3.6/freebayes \
                    --ploidy 1 \
                    --min-alternate-fraction 0.01 \
                    --min-alternate-count 3 \
                    --min-mapping-quality 30 \
                    --min-base-quality 20 \
                    --use-best-n-alleles 2 \
                    -f $assembly_id_path/"$assembly_id".fasta \
                    $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                    > $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf

                    ## --ploidy 1 : haploid genome for e.g. phage 
                    ## --min-alternate-fraction 0.01 : minimum fraction of alternate bases to call a variant (at least 1% or 1/100 of the reads need to support the alternate allele)
                    ## --min-alternate-count 3 : minimum number of alternate bases to call a variant (minimum number of reads supporting the alternate allele for it to be considered a variant.)
                    ## --min-mapping-quality 30 : minimum mapping quality to consider a read for variant calling (minimum mapping quality a read must have to be considered in the variant calling process.)
                    ## --min-base-quality 20 : minimum base quality to consider a base for variant calling (the minimum base quality for a base to be considered in variant calling.)
                    ## --use-best-n-alleles 2: Limits the analysis to the best 2 alleles per position, which can reduce noise and help in situations where one allele is dominant.
                
                    # 2024-11-08 16:17:53
                    # compress vcf file and get normalised vcf file (complex SNPs are split into multiple lines)    
                        conda activate gatk_v4.6.1.0

                        pigz -p 10 -c "$raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf" \
                        > "$raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.gz"

                        /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools norm \
                        -m -any $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.gz \
                        -Ov -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf

                        /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools norm \
                        -m -both -c w $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf \
                        -f $assembly_id_path/"$assembly_id".fasta \
                        -Ov -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf

                        gatk LeftAlignAndTrimVariants \
                        -R $assembly_id_path/"$assembly_id".samtools.fasta \
                        -V $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf \
                        -O $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
                        --split-multi-allelics

                        conda deactivate  

                                            ## 2024-11-08 16:17:53 : NOT GIVING GOOD RESULTS (some SNPs are skipped)
                                            # conda activate vcflib_v1.0.10

                                            #     vcfbreakmulti $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf | \
                                            #     vcfallelicprimitives -k > $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.final_decomposed.vcf

                                            # conda deactivate

                ## convert raw vcf to raw tsv 
                python3 $suppl_scripts/0065_read_mapping_by_minimap2.vcf_to_tsv.py \
                -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
                -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv

                # QUAL>=30: Filters variants to include only those with a quality score (QUAL) greater than or equal to 30. A higher quality score indicates a higher confidence in the variant call.
                # FORMAT/DP>=20: Filters variants to include only those with a depth of coverage (DP) of 20 or more. Depth of coverage refers to how many reads support the variant at that position.
                # INFO/NUMALT<=2: To filter out sites with more than one alternate allele (which are more likely to be complex), you can use the INFO/NUMALT field to exclude these multi-allelic calls:
                # AF>=0.01: frequency of 1 in 100 alleles. Filters variants where the allele frequency (AF) is at least 0.01. Allele frequency represents the proportion of reads supporting the alternate allele versus the total number of reads.

                # 2025-02-12 13:13:25 @Swapnil "for Wallapat P1L1 and P2L1 I have used  -i 'QUAL>=20 && FORMAT/DP>=1 && INFO/NUMALT<=2 && AF>=0.00001'"
                log "STARTED : filtering freebayes variants for $assembly_id.$fastq_id" 
                /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools filter \
                    -i 'QUAL>=30 && FORMAT/DP>=20 && INFO/NUMALT<=2 && AF>=0.01' \
                    $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
                    -Oz -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

                    /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools index \
                    --tbi $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

                log "STARTED : generating consensus sequence for $assembly_id.$fastq_id"
                /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools consensus \
                -f $assembly_id_path/"$assembly_id".fasta \
                -o $raw_files/consensus_sequences/$assembly_id.$fastq_id.consensus.fasta \
                $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

                gunzip -k $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

                ## convert raw vcf to raw tsv 
                python3 $suppl_scripts/0065_read_mapping_by_minimap2.vcf_to_tsv.py \
                -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf \
                -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv

                source /home/groups/VEO/tools/biopython/myenv/bin/activate
                python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_complex_snps.py \
                -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv \
                -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.tsv

                python /home/groups/VEO/scripts_for_users/supplementary_scripts/0065_read_mapping_by_minimap2.tsv_to_vcf.py \
                -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.tsv \
                -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf

                deactivate

                rm $raw_files/vcf/$assembly_id.$fastq_id*.gz
                rm $raw_files/vcf/$assembly_id.$fastq_id*.gz.tbi
            fi

            ## snpEff 
            ## 2024-11-09 07:44:29 need to give the full path? Don't know. Need to check  
            if [ $snp_annotation == "Yes" ]; then
                if [ ! -f $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.snpEff_annotated.vcf.summary.tsv ]; then  
                    genBankFile=$( grep $assembly_id $wd/tmp/genBank_filepath.txt | awk -F'\t' '{print $2}' | head -1 )
                    log "STARTED : snpEff annotation for $assembly_id.$fastq_id $genBankFile" 

                    ## convert_GenBank_to_GFF3_and_FASTA
                    ## the names should be genes.gff and sequence.fa for snpEff to work, DON'T change  
                    mkdir -p $raw_files/tmp/genome_data/$assembly_id > /dev/null 2>&1
                    source /home/groups/VEO/tools/biopython/myenv/bin/activate
                        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_GenBank_to_GFF3_and_FASTA.py \
                        -i $genBankFile \
                        -g $raw_files/tmp/genome_data/$assembly_id/genes.gff \
                        -f $raw_files/tmp/genome_data/$assembly_id/sequences.fa
                    deactivate

                    ## 2025-06-14 22:36:29 sanitise the gff
                    sed -i 's/>//g' $raw_files/tmp/genome_data/$assembly_id/genes.gff

                    cat /home/groups/VEO/scripts_for_users/supplementary_scripts/parameter_files/snpEff.config \
                    | sed "s/genome_id/$assembly_id/g" \
                    > $raw_files/tmp/genome_data/snpEff.$assembly_id.config

                    ## Build the database
                    cur_dir=$(pwd)
                    java -jar /home/groups/VEO/tools/snpeff/v5.2c/snpEff/snpEff.jar build \
                    -gff3 -v \
                    -dataDir $cur_dir/$raw_files/tmp/genome_data/ \
                    -c $raw_files/tmp/genome_data/snpEff.$assembly_id.config \
                    $assembly_id

                    java -jar /home/groups/VEO/tools/snpeff/v5.2c/snpEff/snpEff.jar \
                    -c $raw_files/tmp/genome_data/snpEff.$assembly_id.config \
                    -dataDir $cur_dir/$raw_files/tmp/genome_data/ \
                    $assembly_id \
                    $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf \
                    | sed 's/<DEL>/-/g' > $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf

                    log "STARTED : generating final summary file for $assembly_id.$fastq_id"
                    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/0065_read_mapping_by_minimap2.filter.sh \
                    -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf \
                    -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf.summary

                                            ## suffix product info to ...vcf.snpEff_annotated.vcf.summary.tsv
                                                # grep -v "^#" "$raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf.summary.tsv" \
                                                # | awk -F'|' '{print $NF}' | tr ' ' '_' \
                                                # | while read -r cds; do
                                                #     product=$(grep "$cds" "$raw_files/tmp/genome_data/$assembly_id/genes.gff" | awk -F';' '{print $5}' | awk -F'product=' '{print $2}')
                                                #     sed -i "s/$cds/$cds|$product/g" $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf.summary.tsv
                                                # done

                    ## suffix product info to ...vcf.snpEff_annotated.vcf.summary.tsv               
                    python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0065_get_gene_and_protein.py \
                    -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf.summary \
                    -g $raw_files/tmp/genome_data/$assembly_id/genes.gff \
                    -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf.summary.tsv 

                    sed -i "/#/!s/^/$fastq_id\t/" $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf.summary.tsv

                    awk 'NR > 1' $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv.split.vcf.snpEff_annotated.vcf.summary.tsv >> $raw_files/summary.InsDel.tsv
                    grep -v "#" $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv | sed "s/^/$fastq_id\t/" >> $raw_files/summary.InsDel.unfiltered.tsv
                fi

                elif [ $snp_annotation == "No" ]; then
                log "NOT RUNNING : snpEff annotation for $assembly_id.$fastq_id"
            fi

            source /home/groups/VEO/tools/biopython/myenv/bin/activate
            python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_complex_snps.py \
            -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv \
            -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv.split.tsv
            deactivate

                ## Optional: make count of reads mapped and unmapped to SNPs  
                    # bash /home/groups/VEO/scripts_for_users/supplementary_scripts/0065_read_mapping_by_minimap2.count.sh \
                    # -v $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
                    # -b $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                    # -o $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam.counts.txt

        fi

        if [ -f $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam ] ; then 
            log "COMPRESSING: $assembly_id.$fastq_id.sam.sorted.bam"
            pigz -9 -c $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
            > $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam.gz ;
            log "REMOVING: $assembly_id.$fastq_id.sam.sorted.bam"
            rm -rf $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam
        fi

        if [ -f $raw_files/sam_files/$assembly_id.$fastq_id.sam ] ; then
            log "REMOVING: $assembly_id.$fastq_id.sam"
            rm -rf raw_files/sam_files/$assembly_id.$fastq_id.sam
        fi

        echo "--------------------------------------------------------------------------------"
    done <  $wd/tmp/lists/ABC
############################################################################### 
## footer
    log "The run for sublist : $sublist is completed"
###############################################################################
